# Week 2 Fact Data Modeling
The homework this week will be using the `devices` and `events` dataset

Construct the following eight queries:

- A query to deduplicate `game_details` from Day 1 so there's no duplicates
WITH deduplication AS (

    SELECT *,
          ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id ORDER BY game_id, team_id, player_id) AS row_num
    FROM game_details

) SELECT *
FROM deduplication
WHERE row_num = 1;

- A DDL for an `user_devices_cumulated` table that has:
  - a `device_activity_datelist` which tracks a users active days by `browser_type`
  - data type here should look similar to `MAP<STRING, ARRAY[DATE]>`
    - or you could have `browser_type` as a column with multiple rows for each user (either way works, just be consistent!)

CREATE TABLE user_devices_cumulated (
    user_id TEXT,
    device_id TEXT,
    browser_type TEXT,
    device_activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (user_id, device_id, browser_type, date)
);

- A cumulative query to generate `device_activity_datelist` from `events`

INSERT INTO user_devices_cumulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_cumulated
    WHERE date = '2023-01-30'::date

), today AS (

    select e.user_id::text,
           d.device_id::text,
           d.browser_type,
           e.event_time::date AS date_active ,
           row_number() over(partition by e.user_id, e.device_id, d.browser_type, e.event_time::date order by e.user_id, e.device_id, d.browser_type) AS row_num
    from events e
    inner join devices d on e.device_id = d.device_id
    where e.event_time::date = '2023-01-31'::date
        and e.user_id is not null and e.device_id is not null
), dedup as (

    select *
    from today
    where row_num = 1

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    CASE WHEN t.date_active IS NULL
        THEN y.device_activity_datelist
        ELSE ARRAY[t.date_active] || y.device_activity_datelist END as device_activity_datelist,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM dedup t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id;


- A `datelist_int` generation query. Convert the `device_activity_datelist` column into a `datelist_int` column 

WITH users_devices AS (

    SELECT *
    FROM user_devices_cumulated
    WHERE date = '2023-01-31'::date

), date_series AS (

    select *
    from generate_series('2023-01-01'::date, '2023-01-31'::date, interval '1 day')
    as series_date

), placeholder_ints as (

    select
    case
        when device_activity_datelist @> array [series_date::date]
            then pow(2, 32 - (date - series_date::date))
            else 0
        end as placeholder_int_value,
        *
    from users_devices
    cross join date_series

)
select
    user_id,
    device_id,
    browser_type,
    cast(sum(placeholder_int_value)::bigint as bit(32)) as datelist_int

from placeholder_ints
group by user_id, device_id, browser_type;

- A DDL for `hosts_cumulated` table 
  - a `host_activity_datelist` which logs to see which dates each host is experiencing any activity
  
CREATE TABLE hosts_cumulated (
    host TEXT,
    host_activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (host, date)
);
  
- The incremental query to generate `host_activity_datelist`

insert into hosts_cumulated
WITH yesterday AS (

    select *
    from hosts_cumulated
    where date = '2023-01-03'::date

), today AS (

    SELECT e.host,
           event_time::date AS date_active
    FROM events e
    where e.event_time::date = '2023-01-04'::date
    GROUP BY e.host, event_time::date


)
select
    coalesce(t.host, y.host) as host,
    case when t.date_active is null
        then y.host_activity_datelist
        else array[t.date_active] || y.host_activity_datelist
        end as host_activity_datelist,
    coalesce(t.date_active, y.date + interval '1 day')::date as date
from today t
full outer join yesterday y on t.host = y.host;


- A monthly, reduced fact table DDL `host_activity_reduced`
   - month
   - host
   - hit_array - think COUNT(1)
   - unique_visitors array -  think COUNT(DISTINCT user_id)

CREATE TABLE host_activity_reduced(
    host text,
    month date,
    hit_metric text,
    hit_array REAL[],
    unique_visitors_metric text,
    unique_visitors_array REAL[],
    PRIMARY KEY(host, month, hit_metric, unique_visitors_metric)
);

- An incremental query that loads `host_activity_reduced`
  - day-by-day

insert into host_activity_reduced
with daily_aggr as (

    SELECT e.host,
           e.event_time::date as date_activity,
           count(1) as hits,
           count(distinct e.user_id) unique_visitors
    FROM events e
    where e.event_time::date = '2023-01-06'::date
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
