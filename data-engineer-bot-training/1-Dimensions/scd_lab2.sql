-- A DATATYPE - SEASON STATS STRUCT FOR THE SEASON STATS
CREATE TYPE season_stats AS (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL
);


CREATE TYPE scoring_class AS
    ENUM ('star', 'good', 'average', 'bad');

DROP TABLE IF EXISTS players;
CREATE TABLE players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXT,
    draft_number TEXT,
    -- NEW COLUMN WITH THE SEASON STATS
    season_stats SEASON_STATS[],
    scoring_class scoring_class,
    years_since_last_season INT,
    is_active boolean,
    current_season INTEGER,
    PRIMARY KEY (player_name, current_season)
);

SELECT *
FROM players;

SELECT *
FROM player_seasons;



WITH last_season AS (
    SELECT *
    FROM players
    WHERE current_season = 2000
), this_season AS (
    SELECT *
    FROM player_seasons
    WHERE season = 2001
)
    INSERT INTO players
    SELECT COALESCE(t.player_name, l.player_name) AS player_name,
         COALESCE(t.height, l.height) AS height,
         COALESCE(t.college, l.college) AS college,
         COALESCE(t.country, l.country) AS country,
         COALESCE(t.draft_year, l.draft_year) AS draft_year,
         COALESCE(t.draft_round, l.draft_round) AS draft_round,
         COALESCE(t.draft_number, l.draft_number) AS draft_number,
         CASE WHEN l.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
                 )::season_stats]
            WHEN t.season IS NOT NULL
                THEN l.season_stats || ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
                )::season_stats]
            ELSE l.season_stats END AS season_stats,
        CASE WHEN t.season IS NOT NULL
                THEN
                    CASE WHEN t.pts > 20 THEN 'star'
                          WHEN t.pts > 15 THEN 'good'
                          WHEN t.pts > 10 THEN 'average'
                          ELSE 'bad'
                    END::scoring_class
            ELSE l.scoring_class END AS scoring_class,
        CASE WHEN t.season IS NOT NULL THEN 0
             ELSE l.years_since_last_season + 1
        END AS years_since_last_season,
        CASE WHEN t.season IS NOT NULL
            THEN TRUE
            ELSE FALSE END AS is_active,
        COALESCE(t.season, l.current_season + 1) AS current_season
FROM this_season AS t
FULL OUTER JOIN last_season AS l
ON t.player_name = l.player_name;

SELECT *
FROM players
WHERE player_name = 'Michael Jordan';

WITH unnested AS (
    SELECT player_name, unnest(season_stats) AS season_stats
    FROM players
    WHERE player_name = 'Michael Jordan' AND current_season = 2001
)   SELECT player_name,
           (season_stats::season_stats).*,
           (season_stats::season_stats).pts
    FROM unnested;


-- CREATE A COOL QUERY - GET HOW PLAYERS HOW IMPRIVED
SELECT
    player_name,
    (season_stats[cardinality(season_stats)]::season_stats).season as lastest_season,
    (season_stats[cardinality(season_stats)]::season_stats).pts AS latest_season_pts,
    (season_stats[1]::season_stats).season AS first_season,
    (season_stats[1]::season_stats).pts AS first_season_pts,
    (season_stats[cardinality(season_stats)]::season_stats).pts /
    CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1
        ELSE (season_stats[1]::season_stats).pts
    END
FROM players
WHERE current_season = 2001
ORDER BY 6 DESC;


-- day 2 - create a slow change dimension type 2
-- gold standart - pure indet pontent - the type 2

WITH last_season AS (
    SELECT *
    FROM players
    WHERE current_season = 2000
), this_season AS (
    SELECT *
    FROM player_seasons
    WHERE season = 2001
)
--     INSERT INTO players
    SELECT COALESCE(t.player_name, l.player_name) AS player_name,
         COALESCE(t.height, l.height) AS height,
         COALESCE(t.college, l.college) AS college,
         COALESCE(t.country, l.country) AS country,
         COALESCE(t.draft_year, l.draft_year) AS draft_year,
         COALESCE(t.draft_round, l.draft_round) AS draft_round,
         COALESCE(t.draft_number, l.draft_number) AS draft_number,
         CASE WHEN l.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
                 )::season_stats]
            WHEN t.season IS NOT NULL
                THEN l.season_stats || ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
                )::season_stats]
            ELSE l.season_stats END AS season_stats,
        CASE WHEN t.season IS NOT NULL
                THEN
                    CASE WHEN t.pts > 20 THEN 'star'
                          WHEN t.pts > 15 THEN 'good'
                          WHEN t.pts > 10 THEN 'average'
                          ELSE 'bad'
                    END::scoring_class
            ELSE l.scoring_class END AS scoring_class,
        CASE WHEN t.season IS NOT NULL THEN 0
             ELSE l.years_since_last_season + 1
        END AS years_since_last_season,
        CASE WHEN t.season IS NOT NULL
            THEN TRUE
            ELSE FALSE END AS is_active,
        COALESCE(t.season, l.current_season + 1) AS current_season
FROM this_season AS t
FULL OUTER JOIN last_season AS l
ON t.player_name = l.player_name;


INSERT INTO players
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1996, 2022) AS season
), p AS (
    SELECT
        player_name,
        MIN(season) AS first_season
    FROM player_seasons
    GROUP BY player_name
), players_and_seasons AS (
    SELECT *
    FROM p
    JOIN years y
        ON p.first_season <= y.season
), windowed AS (
    SELECT
        pas.player_name,
        pas.season,
        ARRAY_REMOVE(
            ARRAY_AGG(
                CASE
                    WHEN ps.season IS NOT NULL
                        THEN ROW(
                            ps.season,
                            ps.gp,
                            ps.pts,
                            ps.reb,
                            ps.ast
                        )::season_stats
                END)
            OVER (PARTITION BY pas.player_name ORDER BY COALESCE(pas.season, ps.season)),
            NULL
        ) AS seasons
    FROM players_and_seasons pas
    LEFT JOIN player_seasons ps
        ON pas.player_name = ps.player_name
        AND pas.season = ps.season
    ORDER BY pas.player_name, pas.season
), static AS (
    SELECT
        player_name,
        MAX(height) AS height,
        MAX(college) AS college,
        MAX(country) AS country,
        MAX(draft_year) AS draft_year,
        MAX(draft_round) AS draft_round,
        MAX(draft_number) AS draft_number
    FROM player_seasons
    GROUP BY player_name
)
SELECT
    w.player_name,
    s.height,
    s.college,
    s.country,
    s.draft_year,
    s.draft_round,
    s.draft_number,
    seasons AS season_stats,
    CASE
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 20 THEN 'star'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 15 THEN 'good'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 10 THEN 'average'
        ELSE 'bad'
    END::scoring_class AS scoring_class,
    w.season - (seasons[CARDINALITY(seasons)]::season_stats).season as years_since_last_active,
    (seasons[CARDINALITY(seasons)]::season_stats).season = season AS is_active,
    w.season

FROM windowed w
JOIN static s
    ON w.player_name = s.player_name;

-- 1 WORK WITH THE SCD - CHECK WHICH COLUMNS SLOWLY CHANGE OVER TIME
-- THIS WILL APPLY ON THE CUMMULATIVE players table
SELECT *
FROM players
WHERE current_season = 2022;

-- 2 CREATE SCD TABLE THE CARDINALITY OF PLAYRES IS YEAR
-- SO THE SCD WE HAVE TO STORE FROM WHICH YEAR TO WHICH YEAR THE VALUE OF THE DIMENSION IS FOR EXAMPLE 'bad'
-- WILL TRACK MULTIPLE DIMENSIONS AT TIME

DROP TABLE IF EXISTS players_scd
CREATE TABLE players_scd
(
    player_name TEXT,

    -- columns for tracking
    scoring_class scoring_class,
    is_active boolean,
    -- fields to manage
    start_season integer,
    end_season integer,

    -- date partition of the table
    current_season integer,
    PRIMARY KEY (player_name, start_season)
);

--3 CREATE A RECORD OF SCD FOR ALL SEASONS AND THEN BUILD THE SCD INCREMENTALY
-- CREATE PLAYERS SCD WITHOUT WHERE -
SELECT player_name,
       current_season,
       scoring_class,
       lag(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
       is_active,
       lag(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active

FROM players;

-- so basedon the previous query create an indicator weather change - indicatores in which the dimension change
WITH with_previous AS (
    SELECT player_name,
           current_season,
           scoring_class,
           is_active,
           lag(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
           lag(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active
    FROM players
) SELECT *,
        CASE WHEN scoring_class <> previous_scoring_class THEN 1 ELSE 0 END AS scoring_class_change_indicator,
        CASE WHEN is_active <> previous_is_active THEN 1 ELSE 0 END AS previous_is_active
 FROM with_previous;

-- to track - make it into a one change indicator
-- indicates when we have a change in the dimensions that we want to track
-- to see how long stay the same values and when change
-- later - BE AGGREGATE EVEN THE STREAK AND WILL NOT BE PART OF THE DATASET
-- that last allow to have a scd sorted table
-- because we have the values sorted and aggregated in a way
-- that we have the combination of values for is active and scoring class
-- and in which values have from some start_season to an end_season until it change a got a new value
-- and in that way get the continues values for every entity when change on time
WITH with_previous AS (
    SELECT player_name,
           current_season,
           scoring_class,
           is_active,
           lag(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
           lag(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active
    FROM players
), with_indicatos AS (
SELECT *,
     CASE   WHEN scoring_class <> previous_scoring_class THEN 1
            WHEN is_active <> previous_is_active THEN 1
            ELSE 0 END AS change_indicator
FROM with_previous
), with_streaks AS (
SELECT *,
SUM(change_indicator)
OVER (PARTITION BY player_name ORDER BY current_season) AS streak_identifier
FROM with_indicatos
)
SELECT player_name,
       is_active,
       scoring_class,
       MIN(current_season) AS start_season,
       MAX(current_season) AS end_season
FROM with_streaks
GROUP BY player_name,
       streak_identifier,
       is_active,
       scoring_class
ORDER BY player_name


--TO PERFORM AN INCREMENTAL RUN - FIRST FILTER TO 2021 TO LATER RUN WITH THE LATEST DATA
-- we also add the current season in this case hard-code because in a production scenario
-- could be a parameter in a incremental load on airflow
INSERT INTO players_scd
WITH with_previous AS (
    SELECT player_name,
           current_season,
           scoring_class,
           is_active,
           lag(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
           lag(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active
    FROM players
    where current_season < 2022
), with_indicatos AS (
SELECT *,
     CASE   WHEN scoring_class <> previous_scoring_class THEN 1
            WHEN is_active <> previous_is_active THEN 1
            ELSE 0 END AS change_indicator
FROM with_previous
), with_streaks AS (
SELECT *,
SUM(change_indicator)
OVER (PARTITION BY player_name ORDER BY current_season) AS streak_identifier
FROM with_indicatos
)
SELECT player_name,
       scoring_class,
       is_active,
       --streak_identifier,
       MIN(current_season) AS start_season,
       MAX(current_season) AS end_season,
       2021 AS current_season
FROM with_streaks
GROUP BY player_name,
       streak_identifier,
       is_active,
       scoring_class
ORDER BY player_name, streak_identifier;

select  *
from players_scd;

-- TO PERFORM AND INCREMENTAL LOAD
-- 1 FIRST SEE IF SOMETHING HAS CHANGE
-- with the last_season_scd we want only the last and then add an historical one
-- with the this_season_data we only query one record per entity - the last data, current records
-- assuming that we have all records for 2021 and records that change we will have one more record
-- into the scd, and for those records that does not change only increase the current_season
-- update the season
-- so we will work with new records and changed records

--CREATE THE SCD TYPE
CREATE TYPE scd_type AS (
    scoring_class scoring_class,
    is_active boolean,
    start_season INTEGER,
    current_season INTEGER
);


WITH last_season_scd AS (
    SELECT *
    FROM players_scd
    WHERE current_season = 2021
    AND end_season = 2021
), historical_scd AS (
    SELECT player_name,
           scoring_class,
           is_active,
           start_season,
           end_season
    FROM players_scd
    WHERE current_season = 2021
    AND end_season < 2021
), this_season_data AS (
    SELECT *
    FROM players
    WHERE current_season = 2022
), unchanged_records AS (
    SELECT ts.player_name,
           ts.scoring_class,
           ts.is_active,
           ls.start_season,
           ts.current_season as end_season -- for those that does not change increse end season, because still active
    FROM this_season_data ts
    JOIN last_season_scd ls on ts.player_name = ls.player_name
    WHERE ts.scoring_class = ls.scoring_class
      AND ts.is_active = ls.is_active
), changed_records AS (
    SELECT ts.player_name,
--     ts.scoring_class,
--     ts.is_active,
--     ls.start_season,
--     ts.current_season as end_season, -- for those that does not change increse end season, because still active
    UNNEST(ARRAY[ -- create and array for old data
        ROW(
            ls.scoring_class,
            ls.is_active,
            ls.start_season,
            ls.end_season
            )::scd_type,
        ROW( -- row for news - start season is the current season because is new, also the end season
            ts.scoring_class,
            ts.is_active,
            ts.current_season,
            ts.current_season
            )::scd_type
        ]) AS records
    FROM this_season_data ts
    LEFT JOIN last_season_scd ls
    ON ts.player_name = ls.player_name
    WHERE (ts.scoring_class <> ls.scoring_class
    OR ts.is_active <> ls.is_active)

), unnested_changed_records AS (
    SELECT  player_name,
            (records::scd_type).scoring_class AS scoring_class,
            (records::scd_type).is_active AS is_active,
            (records::scd_type).start_season,
            (records::scd_type).current_season AS end_season

    FROM changed_records
), new_records as ( -- NEW RECORDS
 SELECT ts.player_name,
        ts.scoring_class,
        ts.is_active,
        ts.current_season as start_season,
        ts.current_season as end_season
 FROM this_season_data ts
 LEFT JOIN last_season_scd ls
    ON ts.player_name = ls.player_name
WHERE ls.player_name IS NULL
)
SELECT
    *
FROM historical_scd

UNION ALL

SELECT * FROM unchanged_records

UNION ALL

SELECT * FROM unnested_changed_records

UNION ALL

SELECT * FROM new_records


--- correccion 

--CREATE THE SCD TYPE
CREATE TYPE scd_type AS (
    scoring_class scoring_class,
    is_active boolean,
    start_season INTEGER,
    end_season INTEGER
);



CREATE TYPE scd_type AS (
                    scoring_class scoring_class,
                    is_active boolean,
                    start_season INTEGER,
                    end_season INTEGER
                        )


WITH last_season_scd AS (
    SELECT * FROM players_scd
    WHERE current_season = 2021
    AND end_season = 2021
),
     historical_scd AS (
        SELECT
            player_name,
               scoring_class,
               is_active,
               start_season,
               end_season
        FROM players_scd
        WHERE current_season = 2021
        AND end_season < 2021
     ),
     this_season_data AS (
         SELECT * FROM players
         WHERE current_season = 2022
     ),
     unchanged_records AS (
         SELECT
                ts.player_name,
                ts.scoring_class,
                ts.is_active,
                ls.start_season,
                ts.current_season as end_season
        FROM this_season_data ts
        JOIN last_season_scd ls
        ON ls.player_name = ts.player_name
         WHERE ts.scoring_class = ls.scoring_class
         AND ts.is_active = ls.is_active
     ),
     changed_records AS (
        SELECT
                ts.player_name,
                UNNEST(ARRAY[
                    ROW(
                        ls.scoring_class,
                        ls.is_active,
                        ls.start_season,
                        ls.end_season

                        )::scd_type,
                    ROW(
                        ts.scoring_class,
                        ts.is_active,
                        ts.current_season,
                        ts.current_season
                        )::scd_type
                ]) as records
        FROM this_season_data ts
        LEFT JOIN last_season_scd ls
        ON ls.player_name = ts.player_name
         WHERE (ts.scoring_class <> ls.scoring_class
          OR ts.is_active <> ls.is_active)
     ),
     unnested_changed_records AS (

         SELECT player_name,
                (records::scd_type).scoring_class,
                (records::scd_type).is_active,
                (records::scd_type).start_season,
                (records::scd_type).end_season
                FROM changed_records
         ),
     new_records AS (

         SELECT
            ts.player_name,
                ts.scoring_class,
                ts.is_active,
                ts.current_season AS start_season,
                ts.current_season AS end_season
         FROM this_season_data ts
         LEFT JOIN last_season_scd ls
             ON ts.player_name = ls.player_name
         WHERE ls.player_name IS NULL

     )


SELECT *, 2022 AS current_season FROM (
                  SELECT *
                  FROM historical_scd

                  UNION ALL

                  SELECT *
                  FROM unchanged_records

                  UNION ALL

                  SELECT *
                  FROM unnested_changed_records

                  UNION ALL

                  SELECT *
                  FROM new_records
              ) a