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