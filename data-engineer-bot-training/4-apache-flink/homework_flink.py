import os 
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, DataTypes, TableEnvironment, StreamTableEnvironment
from pyflink.table.expressions import lit, col
from pyflink.table.window import Tumble, Session

def create_events_source_kafka(t_env):
    kafka_key = os.environ.get("KAFKA_WEB_TRAFFIC_KEY", "")
    kafka_secret = os.environ.get("KAFKA_WEB_TRAFFIC_SECRET", "")
    table_name = "events"
    pattern = "yyyy-MM-dd''T''HH:mm:ss.SSS''Z''"

    source_ddl = f"""
        CREATE TABLE {table_name} (
            url VARCHAR,
            referrer VARCHAR,
            user_agent VARCHAR,
            host VARCHAR,
            ip VARCHAR,
            headers VARCHAR,
            event_time VARCHAR,
            event_timestamp AS TO_TIMESTAMP(event_time, '{pattern}'),
            WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '15' SECOND
        ) WITH (
            'connector' = 'kafka',
            'properties.bootstrap.servers' = '{os.environ.get('KAFKA_URL')}',
            'topic' = '{os.environ.get('KAFKA_TOPIC')}',
            'properties.group.id' = '{os.environ.get('KAFKA_GROUP')}',
            'properties.security.protocol' = 'SASL_SSL',
            'properties.sasl.mechanism' = 'PLAIN',
            'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username=\"{kafka_key}\" password=\"{kafka_secret}\";',
            'scan.startup.mode' = 'latest-offset',
            'properties.auto.offset.reset' = 'latest',
            'format' = 'json'
        );
    """

    t_env.execute_sql(source_ddl)

    return table_name

def create_processed_users_events_aggregated_sink_postgres(t_env):

    table_name = 'processed_users_events_aggregated'

    sink_ddl = f"""
         CREATE TABLE {table_name} (
            ip VARCHAR,
            host VARCHAR,
            session_start TIMESTAMP(3),
            session_end   TIMESTAMP(3),
            num_of_events BIGINT
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver'
        );
    """

    t_env.execute_sql(sink_ddl)

    return table_name

# Flink job that sessionizes the input data by IP address and host - Use a 5 minute gap?
def log_aggregation():

    print('Starting Job!')

    # Set up the execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(10 * 1000)
    env.set_parallelism(3)

    # Set up the table environment
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    try:

        source_table = create_events_source_kafka(t_env)
        aggregated_table = create_processed_users_events_aggregated_sink_postgres(t_env)
        
        source = t_env.from_path(source_table)
        sessions = (
                source.
                window(
                    Session.with_gap(lit(5).minutes).on(col("event_timestamp")).alias("s"))
                .group_by(col("s"), col("ip"), col("host"))
                .select(
                    col("ip"),
                    col("host"),
                    col("s").start.alias("session_start"),
                    col("s").end.alias("session_end"),
                    col("host").count.alias("num_of_events")
                )
        )

        sessions.execute_insert(aggregated_table).wait()

    except Exception as e:
        print("Writing records from Kafka to JDBC failed:", str(e))

if __name__ == '__main__':
    log_aggregation()

# What is the average number of web events of a session from a user on Tech Creator
# SELECT AVG(num_of_events)::float AS avg_events_per_session_techcreator
# FROM processed_users_events_aggregated
# WHERE host = 'techcreator.io' OR host LIKE '%.techcreator.io';

# ompare results between different hosts (zachwilson.techcreator.io, zachwilson.tech, lulu.techcreator.io)
# SELECT host, AVG(num_of_events)::float AS avg_events_per_session
# FROM processed_users_events_aggregated
# WHERE host IN ('zachwilson.techcreator.io','zachwilson.tech','lulu.techcreator.io')
# GROUP BY host
# ORDER BY host;
