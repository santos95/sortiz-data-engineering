-- # 1  **DDL for actors table:**
CREATE TYPE films AS (
    film    CHARACTER VARYING,
    votes   INTEGER,
    rating  DECIMAL,
    filmid  CHARACTER VARYING
);

CREATE TYPE quality_class AS
    ENUM('star', 'good', 'average', 'bad');

DROP TABLE IF EXISTS actors;
CREATE TABLE actors (
    actor CHARACTER VARYING,
    actorid CHARACTER VARYING,
    films FILMS[],
    quality_class QUALITY_CLASS,
    is_active BOOLEAN,
    current_year INTEGER,
    PRIMARY KEY (actor, current_year)
);

SELECT MAX(year), MIN(year)
FROM actor_films;


-- #2 Cumulative table generation query:
INSERT INTO actors
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1970, 1971) AS year
), last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = (SELECT MIN(year) FROM years)
), this_year AS (
    SELECT *
    FROM actor_films
    WHERE year = (SELECT MAX(year) FROM years)
), actors_with_films AS (

    SELECT ty.actor,
           ty.actorid,
        ARRAY_AGG(
        ROW (
            ty.film,
            ty.votes,
            ty.rating,
            ty.filmid
            )::films
            ) OVER (PARTITION BY ty.actor ORDER BY ty.year)                AS films,
        AVG(rating) OVER (PARTITION BY ty.actor, ty.year ORDER BY ty.year) AS avg_rating,
        ty.year
    FROM this_year AS ty

), actors_with_films_grouped AS (
    SELECT
        actor,
        actorid,
        films,
        avg_rating,
        year
    FROM actors_with_films
    GROUP BY  actor,actorid,films,avg_rating,year
    ORDER BY actor, year
) SELECT COALESCE(af.actor, ly.actor),
         COALESCE(af.actorid, ly.actorid),
         CASE WHEN ly.films IS NULL
                THEN  af.films
              WHEN af.year IS NOT NULL
                THEN ly.films || af.films
              ELSE ly.films END AS films,
        CASE WHEN af.year IS NOT NULL THEN
            CASE WHEN af.avg_rating > 8 THEN 'star'
                 WHEN af.avg_rating > 7 THEN 'good'
                 WHEN af.avg_rating > 6 THEN 'average'
                 ELSE 'bad'
            END::quality_class
            ELSE ly.quality_class END AS quality_class,
        CASE WHEN af.year IS NOT NULL THEN TRUE ELSE FALSE END AS is_active,
        COALESCE(af.year, ly.current_year + 1) AS current_year
FROM actors_with_films_grouped AS af
FULL OUTER JOIN last_year AS ly ON af.actor = ly.actor;



INSERT INTO actors
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1971, 1972) AS year
), last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = (SELECT MIN(year) FROM years)
), this_year AS (
    SELECT *
    FROM actor_films
    WHERE year = (SELECT MAX(year) FROM years)
), actors_with_films AS (

    SELECT ty.actor,
           ty.actorid,
        ARRAY_AGG(
        ROW (
            ty.film,
            ty.votes,
            ty.rating,
            ty.filmid
            )::films
            ) AS films,
        AVG(rating) AS avg_rating,
        ty.year
    FROM this_year AS ty
    GROUP BY ty.actor, ty.actorid, ty.year
) SELECT COALESCE(af.actor, ly.actor),
         COALESCE(af.actorid, ly.actorid),
         CASE WHEN ly.films IS NULL
                THEN  af.films
              WHEN af.year IS NOT NULL
                THEN ly.films || af.films
              ELSE ly.films END AS films,
        CASE WHEN af.year IS NOT NULL THEN
            CASE WHEN af.avg_rating > 8 THEN 'star'
                 WHEN af.avg_rating > 7 THEN 'good'
                 WHEN af.avg_rating > 6 THEN 'average'
                 ELSE 'bad'
            END::quality_class
            ELSE ly.quality_class END AS quality_class,
        CASE WHEN af.year IS NOT NULL THEN TRUE ELSE FALSE END AS is_active,
        COALESCE(af.year, ly.current_year + 1) AS current_year
FROM actors_with_films AS af
FULL OUTER JOIN last_year AS ly ON af.actor = ly.actor;

-- -- 3. **DDL for `actors_history_scd` table:** Create a DDL for an `actors_history_scd` table with the following features:
-- --     - Implements type 2 dimension modeling (i.e., includes `start_date` and `end_date` fields).
-- --     - Tracks `quality_class` and `is_active` status for each actor in the `actors` table.
-- --
-- 3 - DDL FOR actors_history_scd
DROP TABLE IF EXISTS actors_history_scd;
CREATE TABLE actors_history_scd (
    actor TEXT,
    quality_class quality_class,
    is_active boolean,
    start_year INTEGER,
    end_year INTEGER,
    current_year INTEGER
);

--  4 Backfill query for `actors_history_scd
INSERT INTO actors_history_scd
WITH previous AS (
    SELECT actor,
         current_year,
         quality_class,
         LAG(quality_class, 1) OVER (PARTITION BY actor ORDER BY current_year) AS previous_quality_class,
         is_active,
         LAG(is_active, 1) OVER (PARTITION BY actor ORDER BY current_year)     AS previous_is_active
    FROM actors
), with_flags AS (
    SELECT *,
          CASE  WHEN quality_class <> previous_quality_class THEN 1
                WHEN is_active <> previous_is_active THEN 1
                ELSE 0 END         AS change_flag
   FROM previous
), with_streaks AS (
    SELECT  *,
            SUM(change_flag) OVER (PARTITION BY actor ORDER BY current_year) AS streak_identifier,
            MAX(current_year) OVER () AS current_year_scd
    FROM with_flags
)
SELECT actor,
       quality_class,
       is_active,
       MIN(current_year) AS start_year,
       MAX(current_year) AS end_year,
       current_year_scd
FROM with_streaks
GROUP BY actor, streak_identifier, quality_class, is_active, current_year_scd
ORDER BY actor, start_year;

select *
from actors_history_scd;
-- 5. **Incremental query for `actors_history_scd`:** Write an "incremental" query that combines the previous year's SCD data with new incoming data from the `actors` table.

CREATE TYPE actors_scd_type AS (
    quality_class quality_class,
    is_active boolean,
    start_year integer,
    end_year integer
);

INSERT INTO actors_history_scd
WITH last_year_scd AS (

    SELECT *
    FROM actors_history_scd
    WHERE current_year = 1971
    AND end_year = 1971

), historical_scd AS (

    SELECT actor,
           quality_class,
           is_active,
           start_year,
           end_year
    FROM actors_history_scd
    WHERE current_year = 1971
    AND end_year < 1971

), this_year_data AS (

    SELECT *
    FROM actors
    WHERE current_year = 1972

), unchanged_records AS (

    SELECT td.actor,
             td.quality_class,
             td.is_active,
             ls.start_year,
             td.current_year AS end_year
    FROM this_year_data td
    JOIN last_year_scd ls ON ls.actor = td.actor
    WHERE td.quality_class = ls.quality_class
    AND td.is_active = ls.is_active

), changed_records AS (

    SELECT td.actor,
         UNNEST(
             ARRAY[
                 ROW(
                     ls.quality_class,
                     ls.is_active,
                     ls.start_year,
                     ls.end_year
                     )::actors_scd_type,
                 ROW(
                     td.quality_class,
                     td.is_active,
                     td.current_year,
                     td.current_year
                     )::actors_scd_type
                 ]) AS records
    FROM this_year_data td
    JOIN last_year_scd ls ON ls.actor = td.actor
    WHERE (td.quality_class <> ls.quality_class
               OR td.is_active <> ls.is_active)

), unnest_changed_records AS (

    SELECT actor,
           (records::actors_scd_type).quality_class,
           (records::actors_scd_type).is_active,
           (records::actors_scd_type).start_year,
           (records::actors_scd_type).end_year
    FROM changed_records

), new_records AS (

    SELECT ts.actor,
           ts.quality_class,
           ts.is_active,
           ts.current_year AS start_year,
           ts.current_year AS end_year
    FROM this_year_data ts
    LEFT JOIN last_year_scd ls ON ls.actor = ts.actor
    WHERE ls.actor IS NULL

)

SELECT *, 1972 AS current_year FROM (

    SELECT *
    FROM historical_scd

    UNION ALL

    SELECT *
    FROM unchanged_records

    UNION ALL

    SELECT *
    FROM unnest_changed_records

    UNION ALL

    SELECT *
    FROM new_records

) AS a
ORDER BY 1;

