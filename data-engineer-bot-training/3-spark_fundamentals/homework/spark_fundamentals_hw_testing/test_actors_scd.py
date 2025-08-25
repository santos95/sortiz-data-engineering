from chispa.dataframe_comparer import *
from ..jobs.actors_scd_job import do_actors_scd_transformation
from collections import namedtuple

Actors = namedtuple("Actors", "actor current_year quality_class is_active")
ActorsScd = namedtuple("ActorsScd", "actor quality_class is_active start_year end_year current_year_scd")

def test_scd_generation(spark):
    source_data = [
        Actors("Robert Downey Jr.", 1972, "bad", True),
        Actors("Robert Downey Jr.", 1973, "bad", False),
        Actors("Jeff Bridges", 1972, "good", True),
        Actors("Jeff Bridges", 1973, "average", True)
    ]

    source_df = spark.createDataFrame(source_data)

    actual_df = do_actors_scd_transformation(spark, source_df)

    expected_data = [
        ActorsScd("Jeff Bridges", "good", True, 1972, 1972, 1973),
        ActorsScd("Jeff Bridges", "average", True, 1973, 1973, 1973),
        ActorsScd("Robert Downey Jr.", "bad", True, 1972, 1972, 1973),
        ActorsScd("Robert Downey Jr.", "bad", False, 1973, 1973, 1973)
    ]

    expected_data = spark.createDataFrame(expected_data)

    assert_df_equality(actual_df, expected_data)