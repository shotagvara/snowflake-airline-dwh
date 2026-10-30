# Airline Data Warehouse on Snowflake

A small airline data warehouse built in Snowflake. Apache Airflow orchestrates the data pipeline from an internal Snowflake stage through the raw, staging, and mart layers.

The project demonstrates Snowflake warehouses, schemas, stages, file formats, streams, stored procedures, audit logging, Time Travel, secure views, and row-level security.

## Architecture

```text
Airline Dataset.csv
        |
        v
Internal stage: AIRLINE_DWH.RAW.AIRLINE_STAGE
        | COPY INTO, triggered by Airflow
        v
RAW.AIRLINE_DATA
        | RAW stream + clean/merge procedure
        v
STAGING.AIRLINE_DATA_CLEAN
        | STAGING stream + mart/merge procedure
        v
MART: dimensions and fact table

AUDIT.ETL_AUDIT_LOG records inserted and updated row counts.
```

The internal stage stores the uploaded CSV file in Snowflake. `RAW`, `STAGING`, `MART`, and `AUDIT` are schemas inside the `AIRLINE_DWH` database.

## Snowflake objects

| Object | Purpose |
| --- | --- |
| `AIRLINE_WH` | Virtual warehouse that provides compute for queries. |
| `AIRLINE_DWH` | Database containing the project schemas and data. |
| `RAW` | Internal stage, CSV file format, raw table, stream, and loading procedure. |
| `STAGING` | Cleaned table, stream, and transformation procedure. |
| `MART` | Dimensions, fact table, mart procedure, secure view, and row access policy. |
| `AUDIT` | ETL audit log and Time Travel example tables. |

The loaded dataset contains 98,619 records. The mart includes:

- `DIM_DATE` — 364 rows
- `DIM_AIRPORT` — 9,107 rows
- `DIM_PASSENGER` — 98,619 rows
- `FACT_AIRLINE_TRAVEL` — 98,619 rows

## Airflow pipeline

The manually triggered DAG is named `airline_stage_to_raw`. It uses the Airflow connection `airline_snowflake` and runs three tasks in sequence:

1. `AIRLINE_DWH.RAW.LOAD_AIRLINE_DATA()` copies the staged CSV into `RAW.AIRLINE_DATA`.
2. `AIRLINE_DWH.STAGING.LOAD_AIRLINE_DATA_CLEAN()` reads changes from the raw stream, cleans the data, and merges it into the staging table.
3. `AIRLINE_DWH.MART.LOAD_AIRLINE_MART()` reads changes from the staging stream and merges them into the dimensions and fact table.

The DAG has no automatic schedule and is triggered manually from the Airflow UI. Airflow controls task order and status; Snowflake procedures perform the SQL operations.

## Audit logging

`AIRLINE_DWH.AUDIT.ETL_AUDIT_LOG` records the process name, target table, inserted row count, updated row count, and log timestamp.

On a repeated run, existing records may be counted as updates rather than inserts. A stream may also contain no new rows after its changes have been consumed.

## Time Travel

The SQL examples demonstrate two DDL and two DML operations using Snowflake Time Travel:

- Create a historical clone with `CLONE ... AT (OFFSET => -60*5)`.
- Create a table from a historical query with `CREATE TABLE ... AS SELECT ... AT (OFFSET => -60*5)`.
- Delete a date row from the audit copy.
- Restore the date row from the historical version if it is missing.

These DML examples modify the audit copy, not the original `MART.DIM_DATE` table. `-60*5` refers to approximately five minutes before the query runs; it does not pause execution.

## Secure view and row-level security

`AIRLINE_DWH.MART.VW_FACT_AIRLINE_TRAVEL_SECURE` exposes the fact table through a secure view. The `AIRLINE_COUNTRY_RAP` row access policy is attached to the view and uses `AIRPORT_COUNTRY_CODE` to filter rows.

- `ACCOUNTADMIN` can see all rows.
- `AIRLINE_US_ANALYST` can see rows where `AIRPORT_COUNTRY_CODE = 'US'`.
- Other roles do not see rows through this view.

The policy was verified: `AIRLINE_US_ANALYST` sees 22,104 US rows, while `ACCOUNTADMIN` sees all 98,619 rows.

## Run Airflow locally

Airflow runs in standalone mode in WSL Ubuntu. Docker Compose is not used. The Airflow virtual environment and runtime configuration are stored under the WSL home directory, outside this repository.

From the project directory in WSL:

```bash
source ~/airflow-venv/bin/activate
export AIRFLOW_HOME=~/airflow
mkdir -p "$AIRFLOW_HOME/dags"
cp dags/airline_stage_to_raw.py "$AIRFLOW_HOME/dags/"
airflow standalone
```

Open `http://localhost:8080`, sign in with the local Airflow administrator credentials, find `airline_stage_to_raw`, and trigger it.

The DAG source is stored in this repository's `dags/` folder. Standalone Airflow reads DAG files from `$AIRFLOW_HOME/dags`. After editing the source file, copy it to that folder again, or configure Airflow to use the repository's `dags/` folder directly.

## Configure the Airflow connection

Create a Snowflake connection in the Airflow UI:

- **Connection ID:** `airline_snowflake`
- **Connection type:** Snowflake
- **Account, user, and authentication:** your Snowflake account values
- **Warehouse:** `AIRLINE_WH`
- **Database:** `AIRLINE_DWH`
- **Role:** a role allowed to call the project procedures

Store credentials in Airflow Connections. Do not commit passwords, private keys, account secrets, or generated Airflow credentials to Git.

## Repository layout

```text
.
├── dags/
│   └── airline_stage_to_raw.py
├── sql/                 # Snowflake setup and project SQL scripts
├── README.md
└── .gitignore
```

For local standalone Airflow, a project-level `config/` folder is not required unless the project adds custom configuration files. Airflow keeps its runtime configuration under `AIRFLOW_HOME`. Airflow logs and generated credentials should remain outside the repository.

## Optional components

This project uses an internal stage, so Snowpipe for an external stage is not configured. A BI report is also not included; both are optional in the task description.