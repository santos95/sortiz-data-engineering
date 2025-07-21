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
        -- generates the number of days between the start to end day - so we can get for example from date the different with series
        -- wich days since was active respecto to date for example for this date = 2023 01 31 - and was active 24 - 0000001 - seven days
        ,

        *
    FROM users
    CROSS JOIN series
    WHERE user_id = '137925124111668560'

)
SELECT user_id,
       SUM(placeholder_int_value)
FROM placeholder_ints
GROUP BY user_id;

-- WE CONVERT THE VALUES OF 2 - INTO BITS, SO FOR EACH DAY IN THE MONTH THE USER IS ACTIVE GETS A 1
-- SO THE NUMBER OF ONE IS THE DAYS IN WHICH THE USER WAS ACTIVE
-- IN THAT WAY WE CAN HAVE A COMMULATIVE LIST THAT SHOW USERS ACTIVE
-- IN THAT WAY WE CAN GET THE MONTLY ACTIVE USERS
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
        -- if were active that day - the cast we pass to the next step
        CASE WHEN
            date_active @> ARRAY [series_date::DATE]
            THEN POW(2, 32 - (date - series_date::date))
            ELSE 0 END AS placeholder_int_value

        ,

        *
    FROM users
    CROSS JOIN series
--     WHERE user_id = '439578290726747300'

)
SELECT
    user_id,
    CAST(SUM(placeholder_int_value)::BIGINT AS BIT(32)),
    BIT_COUNT(CAST(SUM(placeholder_int_value)::BIGINT AS BIT(32))) > 0 AS dim_is_montly_active, -- SHOW HOW MANY TIMES WERE ACTIVE IN THE MONTH,
    BIT_COUNT(CAST('11111110000000000000000000000000' AS BIT(32)) &
    CAST(SUM(placeholder_int_value)::BIGINT AS BIT(32))) > 0 AS dim_is_weekly_active
    -- WILL RETURN 1 FOR ANY OF THE 1 THAT ARE PART OF THE FIRST 7 1 - LAST SEVEN DAYS
    -- THE & AND ALLOW TO ONLY RETURN THE 1s OF THE FIRST 7 BITS
    -- SO IN THAT WAY THE VALUE ONLY HAVE THE LAST 7 DAYS OF ACTIVITY
    -- ALLOW TO CREATE A FLAG OF WEEKS ACTIVITY
FROM placeholder_ints
GROUP BY user_id;