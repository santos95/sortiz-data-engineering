
-- CREATE A TABLE THAT HAS ONE ROW PER PLAYER WITH AN ARRAY FOR ALL THE SEASONS
-- THE TEMPORAL COMPONENT WILL BE PUT IT INTO A TYPE
-- player_name - attribute of player, height, country -- things that probable will not will change
-- the table has very duplicate date
-- gp - gamesplayed
-- season -- season name

-- 1 - CREATE A STRUCT - CALLED SEASON STATS
-- IN POSTGRES IS POSSIBLE TO CREATE A TYPE
SELECT *
FROM player_seasons;

-- A DATATYPE - SEASON STATS STRUCT FOR THE SEASON STATS
CREATE TYPE season_stats AS (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL
);

CREATE TYPE scoring_class AS
    ENUM ('start', 'good', 'average', 'bad');

-- 2 CREATE A NEW TABLE THAT WILL HAVE COLUMNS AT PLAYER LEVEL WITH AN ARRAY OF SEASON STATS
-- TO HAVE A ROW WITH THE PLAYER DATA AND WITH THE NEW TYPE ALL THE SEASON DATA FROM DIFFERENT
-- SEASON INTO A SINGLE ROW AND IN THAT WAY COMPACT THE DATA
-- 2.1 SO FOR THAT WE ALL READY HAVE THE DATA THAT CHANGES OVER TIPE - THE STATS
-- 2.2 WE NEED TO CREATE THE TABLE - WE IDENTIFY THE STATIC DATA - THE DATA THAT KEEPS THE SAME OVER THE SEASONS
-- 2.3 FOR THE TABLE WE CREATE A SEASON_STATS ARRAY - AN ARRAY FOR THE NEW TYPE - STRUCT

-- THIS TABLE WILL BE A COMMULATIVE TABLE - SO WE NEED THE CURRENT SEASON FIELD
-- TO IDENTIFY THE LATEST VALUES ON SEASON TABLES S

CREATE TABLE players (
    player_name TEXT,
    heigh TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXT,
    draft_number TEXT,
    -- NEW COLUMN WITH THE SEASON STATS
    season_stats SEASON_STATS[],
    current_season INTEGER,
    scoring_class scoring_class,
    years_since_last_season INT,
    PRIMARY KEY (player_name, current_season)
);

SELECT * FROM players;
-- 3 - HOW TO BUILD THE FULL OUTER JOIN FOR THIS TO CREATE THE CUMMULATIVE
-- IDENTIFY THE FIRST YEAR TO WHICH WORK IT
SELECT MIN(season) FROM player_seasons;

-- BUILD THE QUERY TO WORK WITH CURRET DAY VS YESTERDAY - TO MANAGE THE CUMMULATION
-- WITH TODAY AND YESTERDAY
WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 1995
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 1996
)
--
SELECT *
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name

-- FOR THIS QUERY YESTERDAY IS NULL - BECAUSE WE DONT HAVE DATA FOR 1995

-- 4 COALESCE VALUES THAT DOES NOT CHANGE
-- 4 with the step 4 coalesce the static data over the seasons -
-- in that way we can later hold the data over the seasons into the array keeping the static data
-- for this case only today data is available - because yesterday is not available -
WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 1995
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 1996
)
SELECT COALESCE(t.player_name, y.player_name) AS player_name,
       COALESCE(t.height, y.heigh) AS height,
       COALESCE(t.college, y.college) AS college,
       COALESCE(t.country, y.country) AS country,
       COALESCE(t.draft_year, y.draft_year) AS draft_year,
       COALESCE(t.draft_round, y.draft_round) AS draft_round,
       COALESCE(T.draft_number, y.draft_number) AS draft_number
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;

SELECT * FROM player_seasons;

-- 5 ADD THE ARRAY TO COMMULATE THE VALUES FOR SEASONS INTO THE ARRAY
-- WE CREATE AN ARRAY CANCAT TO SLOWLY ADD THE VALUES - BUILD AN ARRAY OF ROWS OF THE TYPE WE CREATED.

WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 1995
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 1996
)
SELECT COALESCE(t.player_name, y.player_name) AS player_name,
       COALESCE(t.height, y.heigh) AS height,
       COALESCE(t.college, y.college) AS college,
       COALESCE(t.country, y.country) AS country,
       COALESCE(t.draft_year, y.draft_year) AS draft_year,
       COALESCE(t.draft_round, y.draft_round) AS draft_round,
       COALESCE(T.draft_number, y.draft_number) AS draft_number,
       -- case evaluate if the column is null if it - add values for the first - in this case 1996 because yeterday is null
       -- for the else - means that got values - if already got values - concat the (today) values
       CASE WHEN y.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
               )::season_stats] -- CAST AS THE TYPE - STRUC DEFINED
            -- concatenate yester values with today values - if null season do not concatenate to avoid null values
            WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(
                t.season,
                t.gp,
                t.pts,
                t.reb,
                t.ast
                )::season_stats]
            ELSE y.season_stats -- IF t.season is null keeps the actual data until yesterday - kepp the history forward
           END AS season_stats
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;

--SO THE PREVIOS LOGIC MEANS IF NOT EXITS - MEANS THAT YESTERDAY DATA IS NULL
-- WE CREATE THE DATA WITH THE ACTUAL DATA THAT EXISTS - TODAY
-- IF ALREADY HAVE DATA FROM YESTERDAY, WE CONCATENATE THE NEW DATA TO COMMULATE

-- FINAL - THE CURRENT SEASON VALUE
-- WITH THIS WE MATCH WHAT WE SPECT FOR OUR COMULATIVE TABLE

WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 1995
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 1996
)
SELECT COALESCE(t.player_name, y.player_name) AS player_name,
       COALESCE(t.height, y.heigh) AS height,
       COALESCE(t.college, y.college) AS college,
       COALESCE(t.country, y.country) AS country,
       COALESCE(t.draft_year, y.draft_year) AS draft_year,
       COALESCE(t.draft_round, y.draft_round) AS draft_round,
       COALESCE(T.draft_number, y.draft_number) AS draft_number,
       -- case evaluate if the column is null if it - add values for the first - in this case 1996 because yeterday is null
       -- for the else - means that got values - if already got values - concat the (today) values
       CASE WHEN y.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
               )::season_stats] -- CAST AS THE TYPE - STRUC DEFINED
            -- concatenate yester values with today values - if null season do not concatenate to avoid null values
            WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(
                t.season,
                t.gp,
                t.pts,
                t.reb,
                t.ast
                )::season_stats]
            ELSE y.season_stats -- IF t.season is null keeps the actual data until yesterday - kepp the history forward
           END AS season_stats,
       COALESCE(t.season, y.current_season + 1) AS current_season
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;

-- CREATE THIS IN WAY LIKE A DATAPIPELINE
-- INSERT INTO THE PLAYERS TABLE

INSERT INTO players
WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 2000
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 2001
)
SELECT COALESCE(t.player_name, y.player_name) AS player_name,
       COALESCE(t.height, y.heigh) AS height,
       COALESCE(t.college, y.college) AS college,
       COALESCE(t.country, y.country) AS country,
       COALESCE(t.draft_year, y.draft_year) AS draft_year,
       COALESCE(t.draft_round, y.draft_round) AS draft_round,
       COALESCE(T.draft_number, y.draft_number) AS draft_number,
       -- case evaluate if the column is null if it - add values for the first - in this case 1996 because yeterday is null
       -- for the else - means that got values - if already got values - concat the (today) values
       CASE WHEN y.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
               )::season_stats] -- CAST AS THE TYPE - STRUC DEFINED
            -- concatenate yester values with today values - if null season do not concatenate to avoid null values
            WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(
                t.season,
                t.gp,
                t.pts,
                t.reb,
                t.ast
                )::season_stats]
            ELSE y.season_stats -- IF t.season is null keeps the actual data until yesterday - kepp the history forward
           END AS season_stats,
       COALESCE(t.season, y.current_season + 1) AS current_season,
       CASE WHEN t.season IS NOT NULL THEN
           CASE WHEN t.pts > 20 THEN 'start'
                WHEN t.pts > 15 THEN 'good'
                WHEN t.pts > 10 THEN 'average'
                ELSE 'bad'
               END::scoring_class
           ELSE y.scoring_class -- keep the class is retired
        END AS scoring_class,
       CASE WHEN t.season IS NOT NULL THEN 0
            ELSE y.years_since_last_season + 1 -- if not play next season keep incrementing
        END AS years_since_last_season
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;

SELECT *
FROM players
WHERE current_season = 2001
AND player_name = 'Michael Jordan';

-- CREATE A COOL QUERY - GET HOW PLAYERS HOW IMPRIVED
SELECT
    player_name,
    (season_stats[cardinality(season_stats)]::season_stats).pts AS latest_season,
    (season_stats[1]::season_stats).pts AS first_season,
    (season_stats[cardinality(season_stats)]::season_stats).pts /
    CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1
        ELSE (season_stats[1]::season_stats).pts
    END
FROM players
WHERE current_season = 2001
ORDER BY 4 DESC;

-- THIS PROVE THAT WITH COMULATIVE TABLES WE CAN PERFORM HISTORICAL ANALYSIS WITHOUT SHUFFLE
-- WITHOUT GROUPS BY AND OTHER TYPE OF KIND THAT REDUCE PERFORFARM - JUST BY MODELING ACCORDINGLY

-- TEST
INSERT INTO players
WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 2000
), today AS (
    SELECT *
    FROM player_seasons
    WHERE season = 2001
)
SELECT COALESCE(t.player_name, y.player_name) AS player_name,
       COALESCE(t.height, y.heigh) AS height,
       COALESCE(t.college, y.college) AS college,
       COALESCE(t.country, y.country) AS country,
       COALESCE(t.draft_year, y.draft_year) AS draft_year,
       COALESCE(t.draft_round, y.draft_round) AS draft_round,
       COALESCE(T.draft_number, y.draft_number) AS draft_number,
       -- case evaluate if the column is null if it - add values for the first - in this case 1996 because yeterday is null
       -- for the else - means that got values - if already got values - concat the (today) values
       CASE WHEN y.season_stats IS NULL
            THEN ARRAY [ROW(
                    t.season,
                    t.gp,
                    t.pts,
                    t.reb,
                    t.ast
               )::season_stats] -- CAST AS THE TYPE - STRUC DEFINED
            -- concatenate yester values with today values - if null season do not concatenate to avoid null values
            WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(
                t.season,
                t.gp,
                t.pts,
                t.reb,
                t.ast
                )::season_stats]
            ELSE y.season_stats -- IF t.season is null keeps the actual data until yesterday - kepp the history forward
           END AS season_stats,
       COALESCE(t.season, y.current_season + 1) AS current_season
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;


SELECT *
FROM players
WHERE current_season = 1999;

SELECT *
FROM players
WHERE player_name = 'Michael Jordan'


-- TURNS THE PLAYERS TABLE INTO player_seasons again
-- in that way easely we can get back to the previous schema
WITH unnested AS (
SELECT player_name,
       unnest(season_stats) AS season_stats
FROM players
WHERE player_name = 'Michael Jordan'
  AND current_season = 2001
)
SELECT player_name,
       (season_stats::season_stats).*
FROM unnested;


-- WITH THIS ALSO WE CAN AVOID LOSSING THE SORT - TO KEEP RELATED DATA TOGETHER AND PERFORM
-- ANOTHER TECHNIQUE - RUN LENGHT ENCODING
WITH unnested AS (
SELECT player_name,
       unnest(season_stats) AS season_stats
FROM players
WHERE current_season = 2001
)
SELECT player_name,
       (season_stats::season_stats).*
FROM unnested;