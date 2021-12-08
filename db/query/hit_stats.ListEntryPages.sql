with x as (
	select
		first_path as path_id,
		count(*)   as count,
		count(*)   as count_unique
	from session_stats
	where site_id = :site and first_visit >= :start and (last_visit is null or last_visit <= :end)
	group by first_path
	order by count desc
	limit :limit offset :offset
)
select
	x.path_id  as id,
	paths.path as name,
	x.count,
	x.count_unique
from x
join paths using (path_id)
