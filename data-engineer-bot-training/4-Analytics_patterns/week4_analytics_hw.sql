-- The homework this week will be using the players, players_scd, and player_seasons tables from week 1
--
-- A query that does state change tracking for players
--
    -- A player entering the league should be New
    -- A player leaving the league should be Retired
    -- A player staying in the league should be Continued Playing
    -- A player that comes out of retirement should be Returned from Retirement
    -- A player that stays out of the league should be Stayed Retired


WITH players_data AS (

    SELECT p.player_name,
           p.current_season,
           scd.is_active AS season_is_active
    FROM players p
    INNER JOIN players_scd scd ON p.player_name = scd.player_name
    AND p.current_season BETWEEN scd.start_season AND scd.end_season
    ORDER BY p.player_name, p.current_season
)
SELECT p.player_name,
       p.current_season,
       CASE
           WHEN
            (LAG(p.current_season) OVER (ORDER BY p.player_name, p.current_season) IS NULL OR
            p.player_name <> LAG(p.player_name) OVER (ORDER BY p.player_name, p.current_season))
            AND season_is_active THEN 'New'
           WHEN
            LAG(p.current_season) OVER (ORDER BY p.player_name, p.current_season) IS NOT NULL
             AND LAG(p.season_is_active) OVER (ORDER BY p.player_name, p.current_season) = TRUE
             AND p.season_is_active = FALSE THEN 'Retired'
           WHEN
            LAG(p.current_season) OVER (ORDER BY p.player_name, p.current_season) IS NOT NULL
            AND LAG(p.season_is_active) OVER (ORDER BY p.player_name, p.current_season) = TRUE
            AND p.season_is_active = TRUE THEN 'Continued Playing'
           WHEN
            LAG(p.current_season) OVER (ORDER BY p.player_name, p.current_season) IS NOT NULL
            AND LAG(p.season_is_active) OVER (ORDER BY p.player_name, p.current_season) = FALSE
            AND p.season_is_active = TRUE THEN 'Returned from Retirement'
           WHEN
            LAG(p.current_season) OVER (ORDER BY p.player_name, p.current_season) IS NOT NULL
            AND LAG(p.season_is_active) OVER (ORDER BY p.player_name, p.current_season) = FALSE
            AND p.season_is_active = FALSE THEN 'Stayed Retired'
        END AS player_status

FROM players_data AS p;

WITH players_data AS (

    SELECT p.player_name,
           p.current_season,
           scd.is_active AS season_is_active
    FROM players p
    INNER JOIN players_scd scd ON p.player_name = scd.player_name
    AND p.current_season BETWEEN scd.start_season AND scd.end_season
    ORDER BY p.player_name, p.current_season

), players_windowed AS (

    SELECT
        player_name,
        current_season,
        season_is_active,
        LAG(season_is_active) OVER (PARTITION BY player_name ORDER BY current_season) AS prev_is_active_flag,
        LAG(current_season) OVER (PARTITION BY player_name ORDER BY current_season) AS prev_season
    FROM players_data

)
SELECT p.player_name,
       p.current_season,
       CASE
           WHEN
            prev_season IS NULL
            AND season_is_active THEN 'New'
           WHEN
            prev_season IS NOT NULL
             AND prev_is_active_flag = TRUE
             AND p.season_is_active = FALSE THEN 'Retired'
           WHEN
            prev_season IS NOT NULL
            AND prev_is_active_flag = TRUE
            AND p.season_is_active = TRUE THEN 'Continued Playing'
           WHEN
            prev_season IS NOT NULL
            AND prev_is_active_flag = FALSE
            AND p.season_is_active = TRUE THEN 'Returned from Retirement'
           WHEN
           prev_season IS NOT NULL
            AND prev_is_active_flag = FALSE
            AND p.season_is_active = FALSE THEN 'Stayed Retired'
        END AS player_status

FROM players_windowed AS p;


-- A query that uses GROUPING SETS to do efficient aggregations of game_details data
--
-- Aggregate this dataset along the following dimensions
    -- player and team
        -- Answer questions like who scored the most points playing for one team?
    -- player and season
        -- Answer questions like who scored the most points in one season?
    -- team
        -- Answer questions like which team has won the most games?
-- A query that uses window functions on game_details to find out the following things:
--
-- What is the most games a team has won in a 90 game stretch?

-- How many games in a row did LeBron James score over 10 points a game?
-- Please add these queries into a folder homework/<discord-username>
