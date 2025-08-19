from pyspark.sql import SparkSession
from pyspark.sql.functions import expr, col 
from pyspark.sql.functions import broadcast
from pyspark.sql.types import StructType, StructField, StringType, BooleanType, TimestampType, IntegerType, DoubleType
from pyspark.sql import functions as F

# create the spark session
spark = SparkSession.builder.appName("spark_fund_homework").getOrCreate()

# create schemas for the different data sets 
matches_schema = StructType([
    StructField("match_id", StringType(), True),
    StructField("mapid", StringType(), True),
    StructField("is_team_game", BooleanType(), True),
    StructField("playlist_id", StringType(), True),
    StructField("game_variant_id", StringType(), True),
    StructField("is_match_over", BooleanType(), True),
    StructField("completion_date", TimestampType(), True),
    StructField("match_duration", IntegerType(), True),
    StructField("game_mode", StringType(), True),
    StructField("map_variant_id", StringType(), True)
])

match_details_schema = StructType([
    StructField("match_id", StringType(), True),
    StructField("player_gamertag", StringType(), True),
    StructField("previous_spartan_rank", IntegerType(), True),
    StructField("spartan_rank", IntegerType(), True),
    StructField("previous_total_xp", IntegerType(), True),
    StructField("total_xp", IntegerType(), True),
    StructField("previous_csr_tier", IntegerType(), True),
    StructField("previous_csr_designation", IntegerType(), True),
    StructField("previous_csr", IntegerType(), True),
    StructField("previous_csr_percent_to_next_tier", IntegerType(), True),
    StructField("previous_csr_rank", IntegerType(), True),
    StructField("current_csr_tier", IntegerType(), True),
    StructField("current_csr_designation", IntegerType(), True),
    StructField("current_csr", IntegerType(), True),
    StructField("current_csr_percent_to_next_tier", IntegerType(), True),
    StructField("current_csr_rank", IntegerType(), True),
    StructField("player_rank_on_team", IntegerType(), True),
    StructField("player_finished", BooleanType(), True),
    StructField("player_average_life", StringType(), True),
    StructField("player_total_kills", IntegerType(), True),
    StructField("player_total_headshots", IntegerType(), True),
    StructField("player_total_weapon_damage", DoubleType(), True),
    StructField("player_total_shots_landed", IntegerType(), True),
    StructField("player_total_melee_kills", IntegerType(), True),
    StructField("player_total_melee_damage", DoubleType(), True),
    StructField("player_total_assassinations", IntegerType(), True),
    StructField("player_total_ground_pound_kills", IntegerType(), True),
    StructField("player_total_shoulder_bash_kills", IntegerType(), True),
    StructField("player_total_grenade_damage", DoubleType(), True),
    StructField("player_total_power_weapon_damage", DoubleType(), True),
    StructField("player_total_power_weapon_grabs", IntegerType(), True),
    StructField("player_total_deaths", IntegerType(), True),
    StructField("player_total_assists", IntegerType(), True),
    StructField("player_total_grenade_kills", IntegerType(), True),
    StructField("did_win", BooleanType(), True),
    StructField("team_id", IntegerType(), True)
])

medals_match_players_schema = StructType([
    StructField("match_id", StringType(), True),
    StructField("player_gamertag", StringType(), True),
    StructField("medal_id", StringType(), True),
    StructField("count", IntegerType(), True)
])

medals_schema = StructType([
    StructField("medal_id", StringType(), True),
    StructField("sprite_uri", StringType(), True),
    StructField("sprite_left", IntegerType(), True),
    StructField("sprite_top", IntegerType(), True),
    StructField("sprite_sheet_width", IntegerType(), True),
    StructField("sprite_sheet_height", IntegerType(), True),
    StructField("sprite_width", IntegerType(), True),
    StructField("sprite_height", IntegerType(), True),
    StructField("classification", StringType(), True),
    StructField("description", StringType(), True),
    StructField("name", StringType(), True),
    StructField("difficulty", IntegerType(), True)
])

maps_schema = StructType([
    StructField("mapid", StringType(), True),
    StructField("name", StringType(), True),
    StructField("description", IntegerType(), True)
])

# read data from files 
df_matches = spark.read \
    .option("header", "true") \
    .option("inferSchema", False) \
    .schema(matches_schema) \
    .csv("/home/iceberg/data/matches.csv")

df_maps = spark.read \
    .option("header", "true") \
    .option("inferSchema", False) \
    .schema(maps_schema) \
    .csv("/home/iceberg/data/maps.csv")

df_match_details = spark.read \
    .option("header", "true") \
    .option("inferSchema", False) \
    .schema(match_details_schema) \
    .csv("/home/iceberg/data/match_details.csv")

df_medal_matches_players = spark.read \
    .option("header", "true") \
    .option("inferSchema", False) \
    .schema(medals_match_players_schema) \
    .csv("/home/iceberg/data/medals_matches_players.csv")

df_medals = spark.read \
    .option("header", "true") \
    .option("inferSchema", False) \
    .schema(medals_schema) \
    .csv("/home/iceberg/data/medals.csv")

# Disabled automatic broadcast join with `spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")`
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")


# Explicitly broadcast JOINs `medals` and `maps`
df_medals_map = df_medals.join(broadcast(df_maps), how="inner")

# verify broadcast join
df_medals_map.explain()


# create tables for bucketed data sets to perform bucketed join
match_details_ddl_sql = """
CREATE TABLE bootcamp.match_details_bucketed (
    match_id STRING,
    player_gamertag STRING,
    previous_spartan_rank INT,
    spartan_rank INT,
    previous_total_xp INT,
    total_xp INT,
    previous_csr_tier INT,
    previous_csr_designation INT,
    previous_csr INT,
    previous_csr_percent_to_next_tier INT,
    previous_csr_rank INT,
    current_csr_tier INT,
    current_csr_designation INT,
    current_csr INT,
    current_csr_percent_to_next_tier INT,
    current_csr_rank INT,
    player_rank_on_team INT,
    player_finished BOOLEAN,
    player_average_life STRING,
    player_total_kills INT,
    player_total_headshots INT,
    player_total_weapon_damage DOUBLE,
    player_total_shots_landed INT,
    player_total_melee_kills INT,
    player_total_melee_damage DOUBLE,
    player_total_assassinations INT,
    player_total_ground_pound_kills INT,
    player_total_shoulder_bash_kills INT,
    player_total_grenade_damage DOUBLE,
    player_total_power_weapon_damage DOUBLE,
    player_total_power_weapon_grabs INT,
    player_total_deaths INT,
    player_total_assists INT,
    player_total_grenade_kills INT,
    did_win BOOLEAN,
    team_id INT
) USING iceberg
PARTITIONED BY (bucket(16, match_id));
"""

spark.sql(match_details_ddl_sql) 

matches_ddl_sql = """

CREATE TABLE bootcamp.matches_bucketed (
    match_id STRING,
    mapid STRING,
    is_team_game BOOLEAN,
    playlist_id STRING,
    game_variant_id STRING,
    is_match_over BOOLEAN,
    completion_date TIMESTAMP,
    match_duration INT,
    game_mode STRING,
    map_variant_id STRING
)
USING iceberg
PARTITIONED BY (bucket(16, match_id));
"""

spark.sql(matches_ddl_sql)

medals_match_players_ddl_sql = """
CREATE TABLE bootcamp.medals_match_players_bucketed (
    match_id STRING,
    player_gamertag STRING,
    medal_id STRING,
    count INT
)
USING iceberg
PARTITIONED BY (bucket(16, match_id));
"""

spark.sql(medals_match_players_ddl_sql)

# Bucket join `match_details`, `matches`, and `medal_matches_players` on `match_id` with `16` buckets
# write data into the tables
df_match_details.write.mode("append").format("parquet") \
.bucketBy(16, "match_id") \
.saveAsTable("bootcamp.match_details_bucketed")

df_matches.write.mode("append").format("parquet") \
.bucketBy(16, "match_id") \
.saveAsTable("bootcamp.matches_bucketed")

df_medal_matches_players.write.mode("append").format("parquet") \
.bucketBy(16, "match_id") \
.saveAsTable("bootcamp.medals_match_players_bucketed")

# perform bucketed join
matches_joined_data_df = spark.sql("""
SELECT m.match_id,
       m.mapid,
       m.playlist_id,
       md.player_gamertag,
       mmp.medal_id,
       SUM(mmp.count) AS total_medals_counts,
       SUM(md.player_total_kills) AS total_player_kills
FROM bootcamp.matches_bucketed AS m 
INNER JOIN bootcamp.match_details_bucketed AS md 
ON md.match_id = m.match_id
INNER JOIN bootcamp.medals_match_players_bucketed AS mmp 
ON mmp.match_id = m.match_id AND mmp.player_gamertag = md.player_gamertag
GROUP BY 
m.match_id,
m.mapid,
m.playlist_id,
md.player_gamertag,
mmp.medal_id
""")

#   - Aggregate the joined data frame to figure out questions like:
#     - Which player averages the most kills per game?
#     - Which playlist gets played the most?
#     - Which map gets played the most?
#     - Which map do players get the most Killing Spree medals on?

# Which player averages the most kills per game?
avg_kills_per_game_df = matches_joined_data_df.groupBy("player_gamertag") \
    .agg(
        (F.sum("total_player_kills") / F.count("match_id")).alias("avg_kills_per_game")
    ).orderBy(F.desc("avg_kills_per_game"))

avg_kills_per_game_df.show()

# Which playlist gets played the most?
most_played_playlist_df = matches_joined_data_df.groupBy("playlist_id") \
    .agg(
        (F.countDistinct("match_id")).alias("most_played_playlist")
    ).orderBy(F.desc("most_played_playlist"))

most_played_playlist_df.show()

# Which map gets played the most?
most_played_map_df = matches_joined_data_df.groupBy("mapid") \
    .agg(
        (F.countDistinct("match_id")).alias("most_played_map")
    ).orderBy(F.desc("most_played_map"))

most_played_map_df.show()


# Which map do players get the most Killing Spree medals on?
most_killing_spree_medal_df = matches_joined_data_df \
    .join(df_medals, on="medal_id", how="inner") \
    .filter(col("name") == "Killing Spree") \
    .groupBy("mapid") \
        .agg(
            (F.sum("total_medals_counts")).alias("most_killing_spree_medal_df")
        ).orderBy(F.desc("most_killing_spree_medal_df"))

most_killing_spree_medal_df.show()

# - With the aggregated data set - Try different `.sortWithinPartitions` to see which has the smallest data size (hint: playlists and maps are both very low cardinality)
# drop if exists tables to verify sizes
spark.sql("DROP TABLE IF EXISTS bootcamp.matches_agg_plyalists")
spark.sql("DROP TABLE IF EXISTS bootcamp.matches_agg_maps")


spark.sql("""
CREATE TABLE bootcamp.matches_agg_plyalists( 
       match_id STRING,
       mapid STRING,
       playlist_id STRING,
       player_gamertag STRING,
       medal_id STRING ,
       total_medals_counts INTEGER,
       total_player_kills DECIMAL
)
USING iceberg
PARTITIONED BY (playlist_id)
""")

spark.sql("""
CREATE TABLE bootcamp.matches_agg_maps( 
       match_id STRING,
       mapid STRING,
       playlist_id STRING,
       player_gamertag STRING,
       medal_id STRING ,
       total_medals_counts INTEGER,
       total_player_kills DECIMAL
)
USING iceberg
PARTITIONED BY (mapid)
""")

# perform sortWithinPartitions for different fields
matches_agg_plyalists = matches_joined_data_df.sortWithinPartitions(col("playlist_id"))
matches_agg_maps = matches_joined_data_df.sortWithinPartitions(col("mapid"))

# write the data into the tables 
matches_agg_plyalists.write.mode("overwrite").saveAsTable("bootcamp.matches_agg_plyalists")

matches_agg_maps.write.mode("overwrite").saveAsTable("bootcamp.matches_agg_maps")

# check sizes
matches_agg_sizes_df = spark.sql(
"""
SELECT SUM(file_size_in_bytes) as size, COUNT(1) as num_files, 'playlists' 
FROM bootcamp.matches_agg_plyalists.files
UNION ALL
SELECT SUM(file_size_in_bytes) as size, COUNT(1) as num_files, 'map' 
FROM bootcamp.matches_agg_maps.files
"""
)


# the smallest data size for the aggregated data set is for the sortWithinPartitions by playlists
matches_agg_sizes_df.show()