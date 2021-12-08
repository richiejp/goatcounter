with x as (
	select
		last_path as path_id,
		count(*)  as count,
		count(*)  as count_unique
	from session_stats
	where
		site_id = :site and first_visit >= :start and last_visit <= :end
		and first_path = :path_id and last_path is not null
	group by last_path
	order by count desc
	limit :limit offset :offset
)
select
	paths.path as name,
	x.count,
	x.count_unique
from x
join paths using (path_id)


/*
 * bounce:
+                       select
+                               path,
+                               round(cast(sum(first_visit) as float) / count(path) * 100) as bounce
+                       from hits
+                       where
+                               site=? and
+                               bot=0 and
+                               created_at>=? and
+                               created_at<=? and
+                               path in (?)
+                       group by path `
 *
 *
On detail → number of follow-up clicks.
Also on detail -> refs and such
TODO for many the first and last visit are the same, as they never click through.
Set last_visit, last_path, and paths to NULL in that case.
Also cases where paths is [5322606, 5322606]

Maybe just distinct paths?

Also sessions right now are pretty large (17 bytes), times 100 million that's
1.6G, times two now. Maybe create new table?

	create table sessions (
		session_id   autoincrement,
		id           bytea
	);

We can also "vacuum" this regularly by just clearing the "id"; just the
"session_id" is enough really.

Then link to the session_id.

big migration though...

---

Want detail display

	85%      (no follow-up clicks or unknown)
	12%      /somepath
	9%       /asd


select
	last_path
from session_stats
	where
		site_id = 1 and first_visit >= '2021-12-01' and last_visit <= '2021-12-31'
		and path_id = 5322606


Anyway, so aside from the "entrypages" also

*/
