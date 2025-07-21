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
