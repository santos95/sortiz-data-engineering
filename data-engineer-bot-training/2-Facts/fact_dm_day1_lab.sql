-- FACT DATA MODELING

-- tabla to work - game_details
SELECT *
FROM game_details;

-- ONE THING TO BE AWARE OFF -- THE GRAIN OF THE DATA
-- SO WE NEED TO BE AWARE WHICH IS THE GRAIN OF THE DATA
-- The grain of the data - which each row means, the level of detail, which is the unique id of the data
--  So a important step is to identify the problemas or challenges of the data set -
--  for now we got duplicates, lack of order, also the table is in part denormalized like team name and things like that
-- also we need the whats, where, when, how and who
-- for this table we have whats - games, when - lack of when fields
-- 1 - so for this, game, for every fame a team and a player - so check for any duplicates
--
SELECT
    game_id, team_id, player_id, COUNT(*)
FROM game_details
GROUP BY game_id, team_id, player_id
HAVING COUNT(*) > 1;

-- The combination game, team a player must be unique

-- 2 CREATE A FILTER GET RID OF DUPLICATES -
-- # 1 PERFORM A DEDUPLICATION OF THE DATA OF THE FACT TABLE
-- row_num in this case, will able to flag the duplicates - so we can filter only row_num = 1
-- and the row_num = 2 means that there are duplicate data

WITH deduped AS (

    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY game_id, team_id, player_id) AS row_num
    FROM game_details
)
SELECT *
FROM deduped;

-- # 2 FILTER THE DUPLICATES - this is the start query to work with

WITH deduped AS (

    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY game_id, team_id, player_id ) AS row_num
    FROM game_details
)
SELECT *
FROM deduped
WHERE row_num = 1;

-- # 3 We have deduped date - work to complete the requirements for modeling our fact
-- check what columns we need for our fact table based on game_details
-- add the when to the dataset of our fact data -
-- so to get the when of the games, join with games data
-- if we can join something in a cheap way is better to do not include it in out fact table
-- for example fields like team_abbreviation, team_city or something like that can be joined easely with game data
-- Join with teams is cheap because is less that 100 teams
-- so we get rid of that fields, game_date_est yes is important to the analytics about games to manage
-- the volumes to make analytics over time because this data, game data increase a lot compare with teams
-- we have to include the home and visitor team id to allow analytics for if is home or visitor
-- also other data from game master is derive data, like pts or avg and can get it making aggregation of the game_details
-- so we check what columns we need for games and game details
-- for visitors and home team id we get rid of visitors, because we only want to know if is visitor or home
-- we can make a flag for that, the dim_is_playing_at_home
-- from game_details, team_abbriviation, team_city we can get them with a join, so are get rid
-- player_id is neccesary to get more player data in a join - players grows more faster than teams
-- player_name - bases on players table grow, may be we can only use player_id, but
-- for a more practicle fact table - we are going to include player_name to know which player is
-- when doing modeling make columns more useful like the minuts columns in this
INSERT INTO fct_game_details
WITH deduped AS (

    SELECT
        g.game_date_est, -- to manage the time and allow to filder this data over dates
        g.season,
        g.home_team_id,
        g.visitor_team_id,
        gd.*,
        ROW_NUMBER() OVER(PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS row_num -- to dedup
    FROM game_details AS gd
    INNER JOIN games AS g ON gd.game_id = g.game_id
)
SELECT
    game_date_est AS dim_game_date,
    season AS dim_season,
    team_id AS dim_team_id,
    player_id AS dim_player_id,
    player_name AS dim_player_name,
    start_position AS dim_start_position, -- attribute of the player in the game , the position of the player, so we add it
    team_id = home_team_id AS dim_is_playing_at_home,
    COALESCE(POSITION('DNP' IN comment), 0) > 0
        AS dim_did_not_play,
    COALESCE(POSITION('DND' IN comment), 0) > 0
        AS dim_did_not_dress,
    COALESCE(POSITION('NWT' IN comment), 0) > 0
        AS dim_not_with_team,
    CAST(SPLIT_PART(min, ':', 1) AS REAL) +
    CAST(SPLIT_PART(min, ':', 2) AS REAL) / 60 AS m_minutes,
    fgm AS m_fgm,
    fga AS m_fga,
    fg3m AS m_fg3m,
    fg3a AS m_fg3a,
    ftm AS m_ftm,
    fta AS m_fta,
    oreb AS m_oreb,
    dreb AS m_dreb,
    ast AS m_ast,
    stl AS m_stl,
    blk AS m_blk,
    "TO" AS m_turnovers,
    pf AS m_pf,
    pts AS m_pts,
    plus_minus AS m_plus_minus
FROM deduped
WHERE row_num = 1;

SELECT *
FROM fct_game_details;

-- DDL FOR FAC TABLE
-- use names that identify facts, dims for columns and so on
CREATE TABLE fct_game_details (
    dim_game_date DATE,
    dim_season INTEGER,
    dim_team_id INTEGER,
    dim_player_id INTEGER,
    dim_player_name TEXT,
    dim_start_positiion TEXT,
    dim_is_playing_at_home BOOLEAN,
    dim_dit_not_play BOOLEAN,
    dim_dit_not_dress BOOLEAN,
    dim_not_with_team BOOLEAN,
    m_minutes REAL, -- measures
    m_fgm INTEGER,
    m_fga INTEGER,
    m_fg3m INTEGER,
    m_fg3a INTEGER,
    m_ftm INTEGER,
    m_fta INTEGER,
    m_oreb INTEGER,
    m_doreb INTEGER,
    m_ast INTEGER,
    m_stl INTEGER,
    m_blk INTEGER,
    m_turnovers INTEGER,
    m_pf INTEGER,
    m_pts INTEGER,
    m_plus_minus INTEGER,
    PRIMARY KEY (dim_game_date, dim_team_id, dim_player_id)
)


-- ONCE WE HAVE THE FACT TABLE WE CAN EASY PERFORM SOME ANALYSIS LIKE NUMBER OF BAILED GAMES
-- THIS NEW DATASET ALLOW US TO RESOLVE QUESTIONS LIKE WE RESPOND NEXT, IN WAY THAT WITH THE ORIGINAL ONE IS MORE PAINFUL
SELECT fgd.dim_player_name,
       COUNT(1) AS num_games,
       COUNT(CASE WHEN dim_not_with_team THEN 1 END) AS bailed_games,
       CAST(COUNT(CASE WHEN dim_not_with_team THEN 1 END)  AS REAL)  / COUNT(1) AS bailed_prc
FROM fct_game_details AS fgd
GROUP BY fgd.dim_player_name
ORDER BY bailed_prc DESC;
