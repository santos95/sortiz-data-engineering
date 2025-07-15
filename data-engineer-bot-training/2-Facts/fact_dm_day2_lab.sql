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
    CASE WHEN y.date_active IS NULL
        THEN ARRAY [t.date_active]
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
    WHERE date = '2023-01-01'::DATE

), today AS (

    -- GETS THE TODAYS VALUE
    SELECT
        user_id::TEXT,
        event_time::DATE AS date_active
    FROM events
    WHERE event_time::DATE = '2023-01-02'::DATE
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

