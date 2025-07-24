--
-- - A monthly, reduced fact table DDL `host_activity_reduced`
--    - month
--    - host
--    - hit_array - think COUNT(1)
--    - unique_visitors array -  think COUNT(DISTINCT user_id)

CREATE TABLE host_activity_reduced(
    host text,
    month date,
    hit_metric text,
    hit_array REAL[], -- INTEGER ARRAY
    unique_visitors_metric text,
    unique_visitors_array REAL[],
    PRIMARY KEY(host, month, hit_metric, unique_visitors_metric)
);

-- - An incremental query that loads `host_activity_reduced`
--   - day-by-day

insert into host_activity_reduced
with daily_aggr as (

    SELECT e.host,
           e.event_time::date as date_activity,
           count(1) as hits,
           count(distinct e.user_id) unique_visitors
    FROM events e
    where e.event_time::date = '2023-01-05'::date
    and e.user_id is not null
    group by e.host, e.event_time::date

), yest_array as (

    select *
    from host_activity_reduced
    where month = '2023-01-01'::date

)
select
        coalesce(d.host, y.host) as host,
        coalesce(y.month, date_trunc('month', d.date_activity))::date as month,
        'site_hits' as hit_metric,
        case when y.hit_array is not null
                then y.hit_array || array[coalesce(d.hits, 0)]
            when y.hit_array is null
                then array_fill(0, array[coalesce(d.date_activity - y.month, 0)]) || array[coalesce(d.hits, 0)]
            end as hit_array,
        'unique_visitors' as unique_visitors_metric,
        case when y.unique_visitors_array is not null
                then y.unique_visitors_array || array[coalesce(d.unique_visitors, 0)]
             when y.unique_visitors_array is null
                then array_fill(0, array[coalesce(d.date_activity - y.month, 0)]) || array[coalesce(d.unique_visitors, 0)]
            end as unique_visitors_array
from daily_aggr d
full outer join yest_array y on d.host = y.host
on conflict (host, month, hit_metric, unique_visitors_metric)
do update set hit_array = excluded.hit_array, unique_visitors_array = excluded.unique_visitors_array;
