// Copyright © Martin Tournoij – This file is part of GoatCounter and published
// under the terms of a slightly modified EUPL v1.2 license, which can be found
// in the LICENSE file or at https://license.goatcounter.com

package cron

import (
	"context"

	"zgo.at/errors"
	"zgo.at/goatcounter/v2"
	"zgo.at/zdb"
	"zgo.at/zstd/zbool"
)

func updateSiteCounts(ctx context.Context, hits []goatcounter.Hit) error {
	return errors.Wrap(zdb.TX(ctx, func(ctx context.Context) error {
		// Group by day + pathID
		type gt struct {
			total       int
			totalUnique int
			event       zbool.Bool
			hour        string
		}
		grouped := map[string]gt{}
		for _, h := range hits {
			if h.Bot > 0 {
				continue
			}

			hour := h.CreatedAt.Format("2006-01-02 15:00:00")
			k := hour
			v := grouped[k]
			if v.total == 0 {
				v.hour = hour
				v.event = h.Event
			}

			v.total += 1
			if h.FirstSiteVisit {
				v.totalUnique += 1
			}
			grouped[k] = v
		}

		siteID := goatcounter.MustGetSite(ctx).ID
		ins := zdb.NewBulkInsert(ctx, "site_counts", []string{"site_id",
			"hour", "total", "total_unique", "event"})
		if zdb.SQLDialect(ctx) == zdb.DialectPostgreSQL {
			ins.OnConflict(`on conflict on constraint "site_counts#site_id#hour" do update set
				total        = site_counts.total        + excluded.total,
				total_unique = site_counts.total_unique + excluded.total_unique`)

			err := zdb.Exec(ctx, `lock table site_counts in exclusive mode`)
			if err != nil {
				return err
			}
		} else {
			ins.OnConflict(`on conflict(site_id, hour) do update set
				total        = site_counts.total        + excluded.total,
				total_unique = site_counts.total_unique + excluded.total_unique`)
		}

		for _, v := range grouped {
			ins.Values(siteID, v.hour, v.total, v.totalUnique, v.event)
		}
		return ins.Finish()
	}), "cron.updateSiteCounts")
}
