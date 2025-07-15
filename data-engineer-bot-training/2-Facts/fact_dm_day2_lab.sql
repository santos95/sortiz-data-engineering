-- # FACT DATA MODELING LAB2
SELECT  COUNT(*)
FROM events;

SELECT  MIN(event_time) AS min_time,
        MAX(event_time) AS max_time
FROM events;

SELECT  *
FROM events;

-- MAKES A COMMULATIVE AND FIND WHERE DAYS THE DIFFERENTS USERS WERE ACTIVE
-- ## 1 CREATES A TABLE FOR THE COMMULATION
DROP TABLE IF EXISTS users_cumulated;
CREATE TABLE users_cumulated(
    user_id TEXT, -- USE BIGINT BECAUSE THE VALUE IS TO BIG FOR INTEGERS
    -- List of dates in the past where the user was active
    date_active DATE[],
    -- Current date for user
    date DATE,
    PRIMARY KEY(user_id, date)
);

-- # TO CREATE THE COMMULATION WE NEED THE YESTERDAY, THE TODAY AND THE USERS THAT
-- WERE ACTIVE TODAY

-- determinate which makes a user active
-- business rules that define that
-- so:
-- # 1 we create the yesterday
-- # 2 we create the todays data with the data that we are going the comulate
-- # 3 we filter data to get the value from them - we always have to know the issues and the value on the data to get the most
-- # 4 so we group by the date and user_id which means the user activity in that day
-- # 5 once we have that we perform a full outer join and get the fields to map the table structure

-- GENERATES THE FIRST DAY OF DATAA -=
INSERT INTO users_cumulated
WITH yesterday AS (

    -- WE START YESTERDAY - BEFORE THE 01/01/2023
    SELECT *
    FROM users_cumulated
    WHERE date = '2022-12-31'::DATE

), today AS (

    -- GETS THE TODAYS VALUE
    SELECT
        user_id::TEXT,
        event_time::DATE AS date_active
    FROM events
    WHERE event_time::DATE = '2023-01-01'::DATE
     AND user_id IS NOT NULL -- TO AVOID NULL VALUES FOR USERS_ID
    GROUP BY user_id, event_time::DATE
)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    -- COLECT ARRAY OF VALUES
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END
     AS dates_active,
    COALESCE(t.date_active, y.date + interval '1 day') AS date
FROM today t
FULL OUTER JOIN yesterday y
ON t.user_id = y.user_id;

--WORK SUBSEQUENTALY
INSERT INTO users_cumulated
WITH yesterday AS (

    -- WE START YESTERDAY - BEFORE THE 01/01/2023
    SELECT *
    FROM users_cumulated
    WHERE date = '2023-01-30'::DATE

), today AS (

    -- GETS THE TODAYS VALUE
    SELECT
        user_id::TEXT,
        event_time::DATE AS date_active
    FROM events
    WHERE event_time::DATE = '2023-01-31'::DATE
     AND user_id IS NOT NULL -- TO AVOID NULL VALUES FOR USERS_ID
    GROUP BY user_id, event_time::DATE
)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    -- COLECT ARRAY OF VALUES
    CASE WHEN t.date_active IS NULL
        THEN y.date_active
        ELSE ARRAY[t.date_active] || y.date_active END
     AS dates_active,
    COALESCE(t.date_active, y.date + interval '1 day') AS date
FROM today t
FULL OUTER JOIN yesterday y
ON t.user_id = y.user_id;


SELECT *
FROM users_cumulated
ORDER BY 3 DESC

-- CONVERT THE COMULATED - THE DATES INTO DATE LIST
-- FOR THE COMMULATIVE - THE MOST RECENT DATA IS FIRST  (date_active)

SELECT *
FROM generate_series('2023-01-01'::date, '2023-01-31'::date, INTERVAL '1 Day');

-- CREATE THE DATE LIST
-- THE LAST DATA OF THE TABLE
-- CREATE A SERIES OF DATE
-- JOIN BOTH
-- ONCE WE JOIN WE CHECK IF A SERIES DATE IS INSIDE THE DATE ACTIVE AND IF IS ADD A BIT VALUE

WITH users AS (

    SELECT *
    FROM users_cumulated
    WHERE date = '2023-01-31'::date

), series AS (

    SELECT *
    FROM generate_series('2023-01-01'::date, '2023-01-31'::date, INTERVAL '1 Day')
    AS series_date

)
SELECT *
FROM users
CROSS JOIN series
WHERE user_id = '137925124111668560';



WITH users AS (

    SELECT *
    FROM users_cumulated
    WHERE date = '2023-01-31'::date

), series AS (

    SELECT *
    FROM generate_series('2023-01-01'::date, '2023-01-31'::date, INTERVAL '1 Day')
    AS series_date

)
-- COMPARE WITH ARRAYS
-- this check as true if a value is in the array of date_active
SELECT date_active @> ARRAY [series_date::DATE], *
FROM users
CROSS JOIN series
WHERE user_id = '137925124111668560';


-- so now we got the base set the fields how we need them

WITH users AS (

    SELECT *
    FROM users_cumulated
    WHERE date = '2023-01-31'::date

), series AS (

    SELECT *
    FROM generate_series('2023-01-01'::date, '2023-01-31'::date, INTERVAL '1 Day')
    AS series_date

), placeholder_ints AS (

    SELECT
        -- if were active that day
        CAST(CASE WHEN
            date_active @> ARRAY [series_date::DATE]
            THEN POW(2, 32 - (date - series_date::date))::BIGINT
            ELSE 0 END AS BIT(32)) AS placeholder_int_value
        -- generates the number of days between the start to end day
        ,

        *
    FROM users
    CROSS JOIN series
    WHERE user_id = '137925124111668560'

)
SELECT *
FROM placeholder_ints


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
SELECT COUNT(*)
FROM events e
JOIN devices d on e.device_id = e.device_id;

SELECT *
FROM devices;

WITH devices_dedup AS (

    SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY device_id) AS row_num
    FROM devices


) SELECT *
FROM devices_dedup
WHERE row_num = 1
