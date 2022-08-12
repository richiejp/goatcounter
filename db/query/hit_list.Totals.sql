select
	hour,
	sum(total)        as total,
	sum(total_unique) as total_unique
from site_counts
-- {{:no_events where event = 0}}
where
	site_id = :site and hour >= :start and hour <= :end
group by hour
order by hour asc
