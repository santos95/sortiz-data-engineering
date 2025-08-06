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
