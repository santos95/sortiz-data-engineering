-- ## GRAPH DATA MODELING DAY 3 LAB
-- THE FOCUS IS RELATIONSHIP NOT ENTITIES
-- ONLY FOR THE DATA LAYER IN THIS LAB - GRAPH DATA MODEL
-- DATA AGNOSTIC GRAPH MODEL - FOR RELATIONSHIP BETWEEN PLAYERS AND OTHER ENTITIES

-- VERTICES AND ENDGES
-- CREATE THE VERTICES TABLES WITH THE BASIC STRUCTURE FOR AN NODE

-- 1 CREATE A VERTEX TYPE AND THE VERTICES TABLE
CREATE TYPE vertex_type
    AS ENUM('player', 'team', 'game');


CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type, -- enumartion
    properties JSON, -- the properties will be json type because in postgres we dont have a map type but json is similar and more flexyble
    PRIMARY KEY(identifier, type)
);

-- 2 - CREATE THE EDGE TYPE
CREATE TYPE edge_type
    AS ENUM('plays_agains', 'shares_team', 'plays_in', 'plays_on');

-- player plyas on a game, player plays in a team, players share a team, player plays again other player

SELECT *
FROM edges;

CREATE TABLE edges(
    subject_identifier TEXT,
    subject_type vertex_type,
    object_identifier TEXT,
    object_type vertex_type,
    edge_type edge_type,
    properties JSON,
    PRIMARY KEY(subject_identifies, subject_type, object_identifier, object_type, edge_type)
    -- the primary key of the edges all the columns except properties
);

-- 3 - CREATE GAME AS A VERTEX TYPE
INSERT INTO vertices
SELECT
    game_id AS identifier,
    'game'::vertex_type AS type,
    -- create properties adding values in jeson
    json_build_object(
        'pts_home', pts_home,
        'pts_away', pts_away,
        'winning_team', CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END
        ) AS properties
FROM games;

SELECT *
FROM vertices

-- CREATE THE PLAYER VERTEX - FROM game_details to get all the history of players - SO WE AGGREGATE TO GET the data
-- an agregate group
WITH players_agg AS (
    SELECT  player_id                   AS identifier,
            MAX(player_name)            AS player_name,
            COUNT(1)                    AS number_of_games,
            SUM(pts)                    AS total_points,
            ARRAY_AGG(distinct team_id) AS teams
    FROM game_details
    GROUP BY player_id
)
INSERT INTO vertices
SELECT identifier, 'player'::vertex_type,
       json_build_object(
           'player_name', player_name,
           'number_of_games', number_of_games,
           'total_points', total_points,
           'teams', teams
        )
FROM players_agg;

-- LETS CREATE THE TEAMS vertices
WITH teams_deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY team_id) AS row_num
    FROM teams
)
INSERT INTO vertices
SELECT
    team_id AS identifier,
    'team'::vertex_type,
    json_build_object(
        'abbrevation', abbreviation,
        'nickname', nickname,
        'city', city,
        'arena', arena,
        'year_founded', yearfounded
        ) AS properties
FROM teams_deduped
WHERE row_num = 1;

-- CHECK THE VERTICES TABLE
SELECT type, COUNT(*)
FROM vertices
GROUP BY type;

--- 3 start with the edges - the most basic is the plays_in
-- start adding to the edges table
with deduped as (
    select *,
           row_number() over (partition by player_id, game_id) AS row_number
    from game_details
)
INSERT INTO edges
SELECT player_id AS subject_identifier,
       'player'::vertex_type AS subject_type,
       game_id AS object_identifier,
       'game'::vertex_type AS object_type,
       'plays_in'::edge_type AS edge_type,
       json_build_object(
           'start_position', start_position,
           'pts', pts,
           'team_id', team_id,
           'team_abbrevation', team_abbreviation
           ) AS properties
FROM deduped
WHERE row_number = 1;

SELECT *
FROM edges;

SELECT *
FROM vertices;

SELECT
    v.properties ->> 'player_name',
    MAX(CAST(e.properties->>'pts' AS INTEGER))
FROM vertices v
INNER JOIN edges e ON e.subject_identifier = v.identifier
AND e.subject_type = v.type
GROUP BY 1
ORDER BY 2 DESC

-- EDGE OF PLAY AGAINS - EX: KOBE PLAYS AGAIN LEBRON and also the shares teams
with deduped as (
    select *,
           row_number() over (partition by player_id, game_id) AS row_number
    from game_details
), filtered AS (
    select *
    from deduped
    where row_number = 1
)
SELECT f1.player_id,
       f1.player_name,
       f2.player_name,
       CASE WHEN f1.team_abbreviation = f2.team_abbreviation
           THEN 'shares_team'::edge_type
           ELSE 'plays_agains'::edge_type END,
        COUNT(1) AS num_games,
        SUM(f1.pts) AS left_points,
        SUM(f2.pts) AS right_points
FROM filtered f1
JOIN filtered f2 ON f1.game_id = f2.game_id
AND f1.player_name <> f2.player_name
GROUP BY f1.player_id, f1.player_name,
       f2.player_name,
       CASE WHEN f1.team_abbreviation = f2.team_abbreviation
           THEN 'shares_team'::edge_type
           ELSE 'plays_agains'::edge_type END