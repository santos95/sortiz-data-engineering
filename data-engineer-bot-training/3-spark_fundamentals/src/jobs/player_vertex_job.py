from pyspark.sql import SparkSession

query = """


WITH players_agg AS (
    SELECT  player_id                   AS identifier,
            MAX(player_name)            AS player_name,
            COUNT(1)                    AS number_of_games,
            SUM(pts)                    AS total_points,
            MAX( team_id)               AS teams
    FROM game_details
    GROUP BY player_id
)
SELECT   identifier, 
        'player' AS `type`,
        map(
           'player_name', player_name,
           'number_of_games', CAST(number_of_games as STRING),
           'total_points', CAST(total_points AS STRING),
           'teams', CAST(teams AS STRING)
        ) AS properties
FROM players_agg;

"""

def do_player_vertex_transformacion(spark, dataframe):
    dataframe.createOrReplaceTempView("game_details")
    return spark.sql(query)

def main():
    spark = SparkSession.buildaer() \
        .master("local") \
        .appName("player_vertex") \
        .getOrCreate()
    
    output_df = do_player_vertex_transformacion(spark, spark.table("game_details"))
    output_df.write.mode("override").insertInto("edges")
        