WITH yesterday AS (

    SELECT *
    FROM users_growth_accounting
    WHERE date = '2021-12-31'::DATE

), today AS (

    SELECT user_id::text,
           DATE_TRUNC('day', event_time::timestamp) as today_date,
           count(1)
    FROM events
    WHERE event_time::date = '2023-01-01'::DATE
    AND user_id is not null
    GROUP BY user_id, DATE_TRUNC('day', event_time::timestamp)

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(y.first_active_date, t.today_date), -- if new then t.today, else yesterday
    COALESCE(t.today_date, y.last_active_date), -- takes the todays like as last active
    CASE
        WHEN y.user_id IS NULL AND t.user_id IS NOT NULL THEN 'New'
        WHEN y.last_active_date = t.today_date - interval '1 day' THEN 'Retained'
        WHEN y.last_active_date < t.today_date - interval '1 day'  THEN 'Resurrected'
        WHEN t.today_date IS NULL AND y.last_active_date = y.date THEN 'Churned'
        ELSE 'Stale '
            END daily_active_state,
    CASE WHEN 1 = 1 THEN 1 END weekly_active_state,
    COALESCE(y.dates_active,
        ARRAY[]::DATE[]) ||
            CASE WHEN t.user_id IS NOT NULL
                THEN ARRAY [t.today_date]
                ELSE ARRAY []::DATE[]
            END AS date_list,
    COALESCE(t.today_date, y.date + interval '1 day') as date
FROM today t
FULL OUTER JOIN yesterday y
ON t.user_id = y.user_id
;
 CREATE TABLE users_growth_accounting (
     user_id TEXT,
     first_active_date DATE,
     last_active_date DATE,
     daily_active_state TEXT,
     weekly_active_state TEXT,
     dates_active DATE[],
     date DATE,
     PRIMARY KEY (user_id, date)
 );

INSERT INTO users_growth_accounting
WITH yesterday AS (

    SELECT *
    FROM users_growth_accounting
    WHERE date = :pStartDate::DATE

), today AS (

    SELECT user_id::text,
           DATE_TRUNC('day', event_time::timestamp) as today_date,
           count(1)
    FROM events
    WHERE event_time::date = :pEndDate::DATE
    AND user_id is not null
    GROUP BY user_id, DATE_TRUNC('day', event_time::timestamp)

)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(y.first_active_date, t.today_date), -- if new then t.today, else yesterday
    COALESCE(t.today_date, y.last_active_date), -- takes the todays like as last active
    CASE
        WHEN y.user_id IS NULL AND t.user_id IS NOT NULL THEN 'New'
        WHEN y.last_active_date = t.today_date - interval '1 day' THEN 'Retained'
        WHEN y.last_active_date < t.today_date - interval '1 day'  THEN 'Resurrected'
        WHEN t.today_date IS NULL AND y.last_active_date = y.date THEN 'Churned'
        ELSE 'Stale '
            END daily_active_state,
    CASE
        WHEN y.user_id IS NULL THEN 'New'
        WHEN y.last_active_date >= y.date - interval '7 day' THEN 'Retained' -- because get active resently
        WHEN Y.last_active_date < t.today_date - interval '7 day' THEN 'Resurrected' -- check if is active in any point of the seven days before
        WHEN t.today_date IS NULL AND y.last_active_date = y.date - interval '7 day' THEN 'Churned'
        ELSE 'Stale' END
     AS  weekly_active_state,
    COALESCE(y.dates_active,
        ARRAY[]::DATE[]) ||
            CASE WHEN t.user_id IS NOT NULL
                THEN ARRAY [t.today_date]
                ELSE ARRAY []::DATE[]
            END AS date_list,
    COALESCE(t.today_date, y.date + interval '1 day') as date
FROM today t
FULL OUTER JOIN yesterday y
ON t.user_id = y.user_id;


SELECT *
FROM users_growth_accounting
order by date desc

SELECT *
FROM users_growth_accounting
WHERE date = '2023-01-09'::date
AND last_active_date = '2023-01-01'::date
order by date desc

-- USING THE users_growth for survival anlysis
SELECT date, daily_active_state, count(1)
FROM users_growth_accounting
GROUP BY date, daily_active_state;

SELECT date - first_active_date AS days_since_first_active,
       COUNT(CASE
           WHEN daily_active_state IN ('New', 'Retained', 'Resurrected')
            THEN 1
        END),
        COUNT(CASE
           WHEN daily_active_state IN ('New', 'Retained', 'Resurrected')
            THEN 1
        END)::REAL / COUNT(1),
        COUNT(1)
FROM users_growth_accounting
WHERE first_active_date = '2023-01-01'
GROUP BY date - first_active_date
order by 1