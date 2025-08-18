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

WITH dedup AS (

    SELECT
       g.game_id,
       gd.team_id,
       gd.team_abbreviation,
       gd.player_id,
       gd.player_name,
       g.home_team_id,
       g.home_team_wins,
       g.season,
       gd.pts,
       ROW_NUMBER() OVER(PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS row_num
    FROM game_details AS gd
    INNER JOIN games AS g ON gd.game_id = g.game_id

), games_pts AS (

    SELECT
        d.game_id,
        d.player_name,
        d.team_id,
        d.team_abbreviation,
        d.season,
        SUM(COALESCE(pts, 0)) AS total_pts
    FROM dedup AS d
    WHERE row_num = 1
    GROUP BY
        d.game_id,
        d.player_name,
        d.team_id,
        d.team_abbreviation,
        d.season

), teams_wins AS (

    SELECT
        d.game_id,
        d.team_id,
        MAX(d.team_abbreviation) AS team_abbreviation,
        MAX(CASE
                WHEN d.team_id = d.home_team_id AND d.home_team_wins = 1 THEN 1
                WHEN d.team_id <> d.home_team_id AND d.home_team_wins = 0 THEN 1
                ELSE 0 END
            ) AS win_game_flag
    FROM dedup d
    WHERE row_num = 1
    GROUP BY d.game_id, d.team_id

)
SELECT
    COALESCE(g.player_name, '(overall)') AS player_name,
    COALESCE(g.team_abbreviation, '(overall)') AS team,
    COALESCE(g.season::text, '(overall)') AS season,
    SUM(g.total_pts) AS total_pts,
    COUNT(DISTINCT CASE WHEN t.win_game_flag = 1 THEN t.game_id END) AS number_of_games_win
FROM games_pts AS g
INNER JOIN teams_wins AS t ON g.game_id = t.game_id AND g.team_id = t.team_id
GROUP BY GROUPING SETS (
    (g.player_name, g.team_abbreviation),
    (g.player_name, g.season),
    (g.team_abbreviation)
    )
ORDER BY total_pts DESC, number_of_games_win DESC;


-- - A query that uses window functions on `game_details` to find out the following things:
--   - What is the most games a team has won in a 90 game stretch?
--   - How many games in a row did LeBron James score over 10 points a game?

WITH dedup AS (

    SELECT
       gd.game_id,
       gd.team_id,
       gd.team_abbreviation,
       gd.player_id,
       gd.player_name,
       g.game_date_est,
       g.season,
       g.home_team_id,
       g.home_team_wins,
       gd.pts,
       ROW_NUMBER() OVER(PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS row_num
    FROM game_details AS gd
    INNER JOIN games AS g ON gd.game_id = g.game_id


), leBron_points AS (

    SELECT
        player_name,
        game_id,
        game_date_est,
        COALESCE(pts, 0) AS pts
    FROM dedup
    WHERE row_num = 1
    AND player_name = 'LeBron James'
)
, lb_over_10_pts_streak AS (

    SELECT
        player_name,
        game_id,
        CASE
            WHEN pts > 10  THEN 1
            ELSE 0
        END AS over_10_pts_flag,
        SUM(CASE WHEN pts <= 10 THEN 1 ELSE 0 END) OVER (ORDER BY game_date_est ROWS UNBOUNDED PRECEDING) streaks
    FROM leBron_points


), total_lb_over_10_pts_streak AS (

    SELECT player_name,
           streaks,
           COUNT(1) as total_games_over_10_points_streak
    FROM lb_over_10_pts_streak
    WHERE over_10_pts_flag = 1
    GROUP BY player_name, streaks

), team_wins AS (

    SELECT
        DISTINCT
        dp.game_id,
        dp.team_id,
        dp.team_abbreviation,
        dp.game_date_est,
       CASE
            WHEN dp.team_id = dp.home_team_id AND dp.home_team_wins = 1 THEN 1
            WHEN dp.team_id <> dp.home_team_id AND dp.home_team_wins = 0 THEN 1
            ELSE 0 END
        AS wins_flag

    FROM dedup AS dp
    WHERE row_num = 1

), wins_in_90_days  AS (

    SELECT
        tw.team_id,
        tw.team_abbreviation,
        tw.game_date_est,
        tw.wins_flag,
        SUM(wins_flag) OVER (PARTITION BY team_id, team_abbreviation ORDER BY tw.game_date_est ROWS BETWEEN 89 PRECEDING AND CURRENT ROW) AS wins_in_last_90_days
    FROM team_wins tw

), most_wins_in_90_days AS (

    SELECT  w.team_id,
            w.team_abbreviation,
          MAX(wins_in_last_90_days) AS most_win_games_in_90_days
    FROM wins_in_90_days w
    GROUP BY w.team_id, w.team_abbreviation

)
SELECT
    team_id,
    team_abbreviation,
    MAX(most_win_games_in_90_days) AS most_games_won_90_game_stretch,
    player_name,
    MAX(total_games_over_10_points_streak) AS LeBron_total_games_in_row_over_10_pts

FROM  most_wins_in_90_days
CROSS JOIN total_lb_over_10_pts_streak
GROUP BY  team_id, team_abbreviation, player_name
ORDER BY most_games_won_90_game_stretch DESC
LIMIT 1
