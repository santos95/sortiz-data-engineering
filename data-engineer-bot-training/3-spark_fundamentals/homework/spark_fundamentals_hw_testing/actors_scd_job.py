from pyspark.sql import SparkSession

query = """
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
ORDER BY actor, start_year
"""

def do_actors_scd_transformation(spark, dataframe):
    dataframe.createOrReplaceTempView("actors")
    return spark.sql(query)

def main():
    spark = SparkSession.builder \
      .master("local") \
      .appName("actors_scd") \
      .getOrCreate()
    
    output_df = do_actors_scd_transformation(spark, spark.table("actors"))
    output_df.write.mode("overwrite").insertInto("actors_scd")
