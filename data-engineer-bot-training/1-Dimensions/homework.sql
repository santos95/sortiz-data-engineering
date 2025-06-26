
-- --     OR ls.player_name IS NULL -- RECORD THAT IS NOT INTO THE TABLE YET - NEW RECORD
--
-- -- # Dimensional Data Modeling - Week 1
--
-- -- This week's assignment involves working with the `actor_films` dataset. Your task is to construct a series of SQL queries and table definitions that will allow us to model the actor_films dataset in a way that facilitates efficient analysis. This involves creating new tables, defining data types, and writing queries to populate these tables with data from the actor_films dataset
--
-- ## Dataset Overview
-- The `actor_films` dataset contains the following fields:
--
-- - `actor`: The name of the actor.
-- - `actorid`: A unique identifier for each actor.
-- - `film`: The name of the film.
-- - `year`: The year the film was released.
-- - `votes`: The number of votes the film received.
-- - `rating`: The rating of the film.
-- - `filmid`: A unique identifier for each film.
--
-- The primary key for this dataset is (`actor_id`, `film_id`).
--
-- ## Assignment Tasks
--
-- 1. **DDL for `actors` table:** Create a DDL for an `actors` table with the following fields:
--     - `films`: An array of `struct` with the following fields:
-- 		- film: The name of the film.
-- 		- votes: The number of votes the film received.
-- 		- rating: The rating of the film.
-- 		- filmid: A unique identifier for each film.
--
--     - `quality_class`: This field represents an actor's performance quality, determined by the average rating of movies of their most recent year. It's categorized as follows:
-- 		- `star`: Average rating > 8.
-- 		- `good`: Average rating > 7 and ≤ 8.
-- 		- `average`: Average rating > 6 and ≤ 7.
-- 		- `bad`: Average rating ≤ 6.
--     - `is_active`: A BOOLEAN field that indicates whether an actor is currently active in the film industry (i.e., making films this year).
--
-- 2. **Cumulative table generation query:** Write a query that populates the `actors` table one year at a time.
--
-- 3. **DDL for `actors_history_scd` table:** Create a DDL for an `actors_history_scd` table with the following features:
--     - Implements type 2 dimension modeling (i.e., includes `start_date` and `end_date` fields).
--     - Tracks `quality_class` and `is_active` status for each actor in the `actors` table.
--
-- 4. **Backfill query for `actors_history_scd`:** Write a "backfill" query that can populate the entire `actors_history_scd` table in a single query.
--
-- 5. **Incremental query for `actors_history_scd`:** Write an "incremental" query that combines the previous year's SCD data with new incoming data from the `actors` table.

-- 1. **DDL for `actors` table:** Create a DDL for an `actors` table with the following fields:
--     - `films`: An array of `struct` with the following fields:
-- 		- film: The name of the film.
-- 		- votes: The number of votes the film received.
-- 		- rating: The rating of the film.
-- 		- filmid: A unique identifier for each film.
--
--     - `quality_class`: This field represents an actor's performance quality, determined by the average rating of movies of their most recent year. It's categorized as follows:
-- 		- `star`: Average rating > 8.
-- 		- `good`: Average rating > 7 and ≤ 8.
-- 		- `average`: Average rating > 6 and ≤ 7.
-- 		- `bad`: Average rating ≤ 6.
--     - `is_active`: A BOOLEAN field that indicates whether an actor is currently active in the film industry (i.e., making films this year).
--
-- ## Dataset Overview
-- The `actor_films` dataset contains the following fields:
--
-- - `actor`: The name of the actor.
-- - `actorid`: A unique identifier for each actor.
-- - `film`: The name of the film.
-- - `year`: The year the film was released.
-- - `votes`: The number of votes the film received.
-- - `rating`: The rating of the film.
-- - `filmid`: A unique identifier for each film.
SELECT *
FROM actor_films;

select *
from players




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

-- 1970 -- 2021
WITH last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = 1969
), this_year AS (
   SELECT *
   FROM actor_films
   WHERE year = 1970
)
SELECT COALESCE(ts.actor, ls.actor) AS actor,
       COALESCE(ts.actorid, ls.actorid) AS actorid,
       CASE WHEN ls.films IS NULL THEN
            ARRAY[ROW(
                    ts.film,
                    ts.votes,
                    ts.rating,
                    ts.filmid
                )::films]
            WHEN ts.year IS NOT NULL THEN ls.films ||
                ARRAY[ROW(
                    ts.film,
                    ts.votes,
                    ts.rating,
                    ts.filmid
                )::films]
            ELSE ls.films
        END AS films,
        CASE WHEN ts.year IS NOT NULL THEN
            CASE WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 8 THEN 'star'
                 WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 7 THEN 'good'
                 WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 6 THEN 'average'
                 ELSE 'bad'
            END::quality_class
        ELSE ls.quality_class END AS quality_class,
AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year)
FROM this_year AS ts
FULL OUTER JOIN last_year AS ls ON ts.actor = ls.actor
-- 	- `star`: Average rating > 8.
-- 		- `good`: Average rating > 7 and ≤ 8.
-- 		- `average`: Average rating > 6 and ≤ 7.
-- 		- `bad`: Average rating ≤ 6.

SELECT * FROM players
-- 1970 -- 2021
WITH last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = 1969
), this_year AS (
   SELECT *
   FROM actor_films
   WHERE year = 1970
), actor_films  AS (
    SELECT COALESCE(ts.actor, ls.actor) AS actor,
    COALESCE(ts.actorid, ls.actorid) AS actorid,
    CASE WHEN ls.films IS NULL THEN
                ARRAY[ROW(
                    ts.film,
                    ts.votes,
                    ts.rating,
                    ts.filmid
                )::films]
            WHEN ts.year IS NOT NULL THEN ls.films ||
                ARRAY[ROW(
                    ts.film,
                    ts.votes,
                    ts.rating,
                    ts.filmid
                )::films]
            ELSE ls.films
        END AS films,
        CASE WHEN ts.year IS NOT NULL THEN
            CASE WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 8 THEN 'star'
                 WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 7 THEN 'good'
                 WHEN AVG(ts.rating) OVER (PARTITION BY ts.actor ORDER BY year) > 6 THEN 'average'
                 ELSE 'bad'
            END::quality_class
        ELSE ls.quality_class END AS quality_class,
        CASE WHEN ts.year IS NOT NULL THEN TRUE ELSE FALSE END AS is_active,
        COALESCE(ts.year, ls.current_year + 1) AS current_year

    FROM this_year AS ts
    FULL OUTER JOIN last_year AS ls ON ts.actor = ls.actor
)
-- INSERT INTO actors
SELECT actor,
         actorid,
--          ARRAY_AGG(films) AS films,
         films,
         quality_class,
         is_active,
         current_year
FROM actor_films
GROUP BY actor, actorid, quality_class, is_active, current_year;

select * from actors

WITH last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = 1970
), this_year AS (
   SELECT *
   FROM actor_films
   WHERE year = 1971
), actor_with_average AS (
    SELECT ts.actor,
           AVG(ts.rating) AS rating
    FROM this_year AS ts
    GROUP BY ts.actor

), actors_with_films AS (
SELECT  COALESCE(ts.actor, ls.actor)     AS actor,
        COALESCE(ts.actorid, ls.actorid) AS actorid,
        ARRAY_REMOVE(
           ARRAY_AGG(
           CASE
               WHEN ts.year IS NOT NULL THEN
                   ROW (
                       ts.film,
                       ts.votes,
                       ts.rating,
                       ts.filmid
                       )::films
               END)
           OVER (PARTITION BY ts.actor ORDER BY COALESCE(ts.year, ls.current_year)),
           NULL) AS films,
            CASE WHEN ts.year IS NOT NULL THEN
                CASE WHEN av.rating > 8 THEN 'star'
                     WHEN av.rating > 7 THEN 'good'
                     WHEN av.rating > 6 THEN 'average'
                     ELSE 'bad'
                END::quality_class END AS quality_class,
            CASE WHEN ts.year IS NOT NULL THEN TRUE ELSE FALSE END AS is_active,
            COALESCE(ts.year, ls.current_year + 1) AS current_year
    FROM this_year AS ts
    FULL OUTER JOIN last_year AS ls ON ts.actor = ls.actor
    LEFT JOIN actor_with_average AS av on av.actor = ts.actor

)
-- INSERT INTO actors
SELECT *
FROM actors_with_films af
GROUP BY actor, actorid, films, quality_class, is_active, current_year
ORDER BY 1;

SELECT *
FROM actor_films
WHERE actor = 'John Huston' and year = 1970
--     GROUP BY COALESCE(ts.actor, ls.actor), COALESCE(ts.actorid, ls.actorid)
-- )
-- INSERT INTO actors
SELECT actor,
         actorid,
         ARRAY_AGG(films) AS films,
         films,
         quality_class,
         is_active,
         current_year
FROM actor_films
GROUP BY actor, actorid, quality_class, is_active, current_year;


WITH last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = 1970
),
this_year AS (
    SELECT *
    FROM actor_films
    WHERE year = 1971
),
ratings_this_year AS (
    SELECT actorid, AVG(rating) AS avg_rating
    FROM this_year
    GROUP BY actorid
)
    SELECT
        COALESCE(ty.actor, ly.actor) AS actor,
        COALESCE(ty.actorid, ly.actorid) AS actorid,

        CASE
            WHEN ly.films IS NULL THEN
                ARRAY[ROW(ty.film, ty.votes, ty.rating, ty.filmid)::FILMS]
            WHEN ty.year IS NOT NULL THEN ly.films || ARRAY[row(ty.film, ty.votes, ty.rating, ty.filmid)::FILMS]
            ELSE ly.films
        END AS films,

        CASE
            WHEN ry.avg_rating IS NOT NULL THEN
                CASE
                    WHEN ry.avg_rating > 8 THEN 'star'
                    WHEN ry.avg_rating > 7 THEN 'good'
                    WHEN ry.avg_rating > 6 THEN 'average'
                    ELSE 'bad'
                END::quality_class
            ELSE ly.quality_class
        END AS quality_class,

        CASE WHEN ty.year IS NOT NULL THEN TRUE ELSE FALSE END AS is_active,

        COALESCE(ty.year, ly.current_year + 1) AS current_year

    FROM this_year ty
    FULL OUTER JOIN last_year ly ON ty.actorid = ly.actorid
    LEFT JOIN ratings_this_year ry ON COALESCE(ty.actorid, ly.actorid) = ry.actorid

-- INSERT INTO actors
SELECT *
FROM updated_actors;


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
)
    SELECT
        pas.player_name,
        pas.season,
--         ARRAY_REMOVE(
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
                END )
            OVER (PARTITION BY pas.player_name ORDER BY COALESCE(pas.season, ps.season)),
            NULL
        --) AS seasons
    FROM players_and_seasons pas
    LEFT JOIN player_seasons ps
        ON pas.player_name = ps.player_name
        AND pas.season = ps.season
    ORDER BY pas.player_name, pas.season

