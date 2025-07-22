-- DAY 3 FACT DATA MODELING LAB

CREATE TABLE array_metrics(
    user_id numeric,
    month_start date,
    metric_name text,
    metric_array REAL[], -- INTEGER ARRAY
    PRIMARY KEY(user_id, month_start, metric_name)
)

-- TO CREATE ARRAY METRICS
-- 1 thins about partitions --
-- 1 - create the daily aggregate function
-- 2 - we need yesterday aggregate - last_month_aggregate
-- 3 - create and fill the array of values

truncate table array_metrics

insert into array_metrics
with daily_aggregate as (

    select user_id,
           event_time::date as date,
           count(1) as num_site_hits
    from events
    where  event_time::date = '2023-01-02'::date
        and user_id is not null
    group by user_id, event_time::date

), yesterday_array as (

    select *
    from array_metrics
    where month_start::date = '2023-01-01'::date

)
select coalesce(d.user_id, y.user_id) as user_id,
       coalesce(y.month_start, date_trunc('month', d.date))::date as month_start,
       'site_hits' as metric_name,
       case when y.metric_array is not null
                then y.metric_array || array[coalesce(d.num_site_hits, 0)]
            when y.metric_array is null
                then array_fill(0, array[coalesce(d.date - y.month_start, 0)]) || array[coalesce(d.num_site_hits, 0)]
        end as metric_array
from daily_aggregate d
full outer join yesterday_array y on y.user_id = d.user_id
on conflict (user_id, month_start, metric_name)
do update set metric_array = excluded.metric_array;



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
    PRIMARY KEY(host, month, hit_array, unique_visitors_array)
);


with daily_aggr as (

    SELECT e.host,
           e.event_time::date as date_activity,
           count(1) as hits,
           count(distinct e.user_id) unique_visitors
    FROM events e
    where e.event_time::date = '2023-01-01'::date
    and e.user_id is not null
    group by e.host, e.event_time::date

), yest_array as (

    select *
    from host_activity_reduced
    where month = '2023-01-01'::date

)
select coalesce(d.host, y.host) as host,
       coalesce(y.month, date_trunc('month', d.date_activity))::date as month,
       'site_hits' as hit_metric,
       case when y.hit_array is not null
                then y.hit_array || array[coalesce(d.hits, 0)]
            when y.hit_array is null
                    then
        end
from daily_aggr d
full outer join yest_array y on d.host = y.host

