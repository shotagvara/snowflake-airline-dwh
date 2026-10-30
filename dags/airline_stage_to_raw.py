from airflow.sdk import dag, task
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

def run_snowflake(sql):
    hook = SnowflakeHook(snowflake_conn_id="airline_snowflake")
    hook.run(sql, autocommit=True)

@dag(
    dag_id="airline_stage_to_raw",
    schedule=None,
    catchup=False,
    tags=["airline", "snowflake"],
)
def airline_stage_to_raw():
    @task
    def load_airline_data():
        run_snowflake("CALL AIRLINE_DWH.RAW.LOAD_AIRLINE_DATA()")

    @task
    def load_staging_data():
        run_snowflake("CALL AIRLINE_DWH.STAGING.LOAD_AIRLINE_DATA_CLEAN()")

    @task
    def load_mart_data():
        run_snowflake("CALL AIRLINE_DWH.MART.LOAD_AIRLINE_MART()")

    load_airline_data() >> load_staging_data()>>load_mart_data()

airline_stage_to_raw()