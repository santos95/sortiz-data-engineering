from chispa.dataframe_comparer import * 
from ..jobs.player_vertex_job import do_player_vertex_transformacion
from collections import namedtuple


game_details = namedtuple("game_details", "player_id player_name team_id pts")
PlayerVertex = namedtuple("PlayerVertex", "identifier type properties")

# create fake input data to test
def test_vertex_generation(spark):

    input_data = [
        game_details(2544, "LeBron James", 1610612739, 25),
        game_details(2544, "LeBron James", 1610612739, 30),
        game_details(201939, "Stephen Curry", 1610612744, 24),
        game_details(201939, "Stephen Curry", 1610612744, 25)
    ]

    input_dataframe = spark.createDataFrame(input_data)
    actual_df = do_player_vertex_transformacion(spark, input_dataframe)

    expected_output = [
        PlayerVertex(
            identifier=2544,
            type='player',
            properties={
                'player_name': 'LeBron James',
                'number_of_games': '2',
                'total_points': '55',
                'teams': '1610612739'
            }
        ),
        PlayerVertex(
            identifier=201939,
            type='player',
            properties={
                'player_name': 'Stephen Curry',
                'number_of_games': '2',
                'total_points': '49',
                'teams': '1610612744'
            }
        )
    ]

    expected_df = spark.createDataFrame(expected_output)
    assert_df_equality(actual_df, expected_df, ignore_nullable=True)
