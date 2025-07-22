
-- The homework this week will be using the `devices` and `events` dataset
--
-- Construct the following eight queries:
--
-- - A query to deduplicate `game_details` from Day 1 so there's no duplicates


WITH deduplication AS (

    SELECT *,
          ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id) AS row_num
    FROM game_details

) SELECT *
FROM deduplication
WHERE row_num = 1;

-- - A DDL for an `user_devices_cumulated` table that has:
--   - a `device_activity_datelist` which tracks a users active days by `browser_type`
--   - data type here should look similar to `MAP<STRING, ARRAY[DATE]>`
--     - or you could have `browser_type` as a column with multiple rows for each user (either way works, just be consistent!)
CREATE TABLE user_devices_comulated (
    user_id TEXT,
    device_id TEXT,
    browser_type TEXT,
    date_active DATE[],
    date DATE,
    PRIMARY KEY (user_id, device_id, browser_type, date)
);

CREATE TABLE user_devices_comulated (
    user_id TEXT,
    device_id TEXT,
    date_active DATE[],
    date DATE,
    PRIMARY KEY (user_id, device_id, date)
);


CREATE TABLE user_devices_comulated (
    user_id TEXT,
    device_id TEXT,
    browser_type TEXT,
    date_active DATE[],
    date DATE,
    PRIMARY KEY (user_id, device_id, browser_type, date)
);


-- - A cumulative query to generate `device_activity_datelist` from `events`
select user_id, device_id, event_time--, count(*)
from events
where user_id is not null
group by user_id, device_id, event_time

INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2022-12-31'::DATE

), today AS (

    select user_id::text,
           device_id::text,
           event_time::date AS date_active, --,
           row_number() over(partition by user_id, device_id, event_time::date) AS row_num
    from events
    where event_time::date = '2023-01-01'::date
        and user_id is not null and device_id is not null
   -- group by user_id, device_id, event_time::DATE

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1;


INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2023-01-01'::DATE

), today AS (

    select user_id::text,
           device_id::text,
           event_time::date AS date_active, --,
           row_number() over(partition by user_id, device_id, event_time::date) AS row_num
    from events
    where event_time::date = '2023-01-02'::date
        and user_id is not null and device_id is not null
   -- group by user_id, device_id, event_time::DATE

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1;


-- v2
INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2022-12-31'::DATE

), today AS (

    select e.user_id::text,
           d.device_id::text,
           d.browser_type,
           e.event_time::date AS date_active, --,
           row_number() over(partition by e.user_id, e.device_id, d.browser_type, e.event_time::date) AS row_num
    from events e
    inner join devices d on e.device_id = d.device_id
    where e.event_time::date = '2023-01-01'::date
        and e.user_id is not null and e.device_id is not null

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1;


INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = :pStartDate::DATE

), today AS (

    select e.user_id::text,
           d.device_id::text,
           d.browser_type,
           e.event_time::date AS date_active, --,
           row_number() over(partition by e.user_id, e.device_id, d.browser_type, e.event_time::date) AS row_num
    from events e
    inner join devices d on e.device_id = d.device_id
    where e.event_time::date = :pEndDate::date
        and e.user_id is not null and e.device_id is not null

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1;


-- - A `datelist_int` generation query. Convert the `device_activity_datelist` column into a `datelist_int` column
WITH users_devices AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2023-01-31'::date

), date_series AS (

    select *
    from generate_series('2023-01-01'::date, '2023-01-31'::date, interval '1 day')
    as series_date

), placeholder_ints as (

    select
    case
        when date_active @> array [series_date::date]
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
    cast(sum(placeholder_int_value)::bigint as bit(32))

from placeholder_ints
group by user_id, device_id, browser_type


-- - A cumulative query to generate `device_activity_datelist` from `events`
select user_id, device_id, event_time--, count(*)
from events
where user_id is not null
group by user_id, device_id, event_time

INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2022-12-31'::DATE

), today AS (

    select user_id::text,
           device_id::text,
           event_time::date AS date_active, --,
           row_number() over(partition by user_id, device_id, event_time::date) AS row_num
    from events
    where event_time::date = '2023-01-01'::date
        and user_id is not null and device_id is not null
   -- group by user_id, device_id, event_time::DATE

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1


INSERT INTO user_devices_comulated
WITH yesterday AS (

    SELECT *
    FROM user_devices_comulated
    WHERE date = '2023-01-01'::DATE

), today AS (

    select user_id::text,
           device_id::text,
           event_time::date AS date_active, --,
           row_number() over(partition by user_id, device_id, event_time::date) AS row_num
    from events
    where event_time::date = '2023-01-02'::date
        and user_id is not null and device_id is not null
   -- group by user_id, device_id, event_time::DATE

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.device_id, y.device_id) AS device_id,
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END as date_active,
    COALESCE(t.date_active, y.date + interval '1 day')::date AS date
FROM today t
FULL OUTER JOIN yesterday y ON t.user_id = y.user_id AND t.device_id = y.device_id
WHERE t.row_num = 1;

SELECT *
FROM user_devices_comulated
ORDER BY user_id, device_id


--
-- - A DDL for `hosts_cumulated` table
--   - a `host_activity_datelist` which logs to see which dates each host is experiencing any activity
--

CREATE TABLE hosts_cumulated (
    host TEXT,
    activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (host, date)
);

CREATE TABLE hosts_cumulated2 (
    host TEXT,
    user_id TEXT,
    activity_datelist DATE[],
    date DATE,
    PRIMARY KEY (host, user_id, date)
);
-- - The incremental query to generate `host_activity_datelist`

insert into hosts_cumulated
WITH yesterday AS (

    select *
    from hosts_cumulated
    where date = '2022-12-31'::date

), today AS (

    SELECT e.host,
           event_time::date AS date_active
    FROM events e
    where e.event_time::date = '2023-01-01'::date
    GROUP BY e.host, event_time::date


)
select
    coalesce(t.host, y.host) as host,
    case when t.date_active is null
        then y.activity_datelist
        else array[t.date_active] || y.activity_datelist
        end as activity_datelist,
    coalesce(t.date_active, y.date + interval '1 day')::date as date
from today t
full outer join yesterday y on t.host = y.host


insert into hosts_cumulated
WITH yesterday AS (

    select *
    from hosts_cumulated
    where date = :pStartDay::date

), today AS (

    SELECT e.host,
           event_time::date AS date_active
    FROM events e
    where e.event_time::date = :pEndDate::date
    GROUP BY e.host, event_time::date


)
select
    coalesce(t.host, y.host) as host,
    case when t.date_active is null
        then y.activity_datelist
        else array[t.date_active] || y.activity_datelist
        end as activity_datelist,
    coalesce(t.date_active, y.date + interval '1 day')::date as date
from today t
full outer join yesterday y on t.host = y.host


insert into hosts_cumulated2
WITH yesterday AS (

    select *
    from hosts_cumulated2
    where date = :pStartDay::date

), today AS (

    SELECT e.host,
           e.user_id::text as user_id,
           event_time::date AS date_active
    FROM events e
    where e.event_time::date = :pEndDate::date
        and e.user_id is not null
    GROUP BY e.host, e.user_id, event_time::date


)
select
    coalesce(t.host, y.host) as host,
    coalesce(t.user_id, y.user_id) as user_id,
    case when t.date_active is null
        then y.activity_datelist
        else array[t.date_active] || y.activity_datelist
        end as activity_datelist,
    coalesce(t.date_active, y.date + interval '1 day')::date as date
from today t
full outer join yesterday y on t.host = y.host and t.user_id = y.user_id

    SELECT e.host,
           e.user_id,
           event_time::date AS date_active
    FROM events e
    --where e.event_time::date = :pEndDate::date
    GROUP BY e.host, e.user_id, event_time::date