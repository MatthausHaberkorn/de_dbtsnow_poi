## Prepare Snowflake

### create dbt user in snowflake

- used worksheet in snowflake for executing the queries

```sql
-- Use an admin role
USE ROLE ACCOUNTADMIN;

-- Create the `elt` role
CREATE ROLE IF NOT EXISTS elt;
GRANT ROLE elt TO ROLE ACCOUNTADMIN;

-- Create the default warehouse if necessary
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE elt;

-- Create the `dbt` user and assign to role
CREATE USER IF NOT EXISTS dbt
  PASSWORD='pwd'
  LOGIN_NAME='user'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE='elt'
  DEFAULT_NAMESPACE='POIFRANCE.RAW'
  COMMENT='DBT user used for data transformation';
GRANT ROLE elt to USER user;

-- Create our database and schemas
CREATE DATABASE IF NOT EXISTS POIFRANCE;
CREATE SCHEMA IF NOT EXISTS POIFRANCE.RAW;

-- Set up permissions to role `elt`
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE elt;
GRANT ALL ON DATABASE POIFRANCE to ROLE elt;
GRANT ALL ON ALL SCHEMAS IN DATABASE POIFRANCE to ROLE elt;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE POIFRANCE to ROLE elt;
GRANT ALL ON ALL TABLES IN SCHEMA POIFRANCE.RAW to ROLE elt;
GRANT ALL ON FUTURE TABLES IN SCHEMA POIFRANCE.RAW to ROLE elt;
```

### Raw data upload

- used snowsql for further configs

#### json stage

- create json format

```sql
CREATE OR REPLACE FILE FORMAT myjsonformat
	TYPE = 'JSON'
	STRIP_OUTER_ARRAY = TRUE;
```

- create staging table

```sql
CREATE OR REPLACE STAGE my_json_stage
    FILE_FORMAT = myjsonformat;
```

- upload json files

```sql
Put file:///<path>*json @my_json_stage
    AUTO_COMPRESS=TRUE;
```

- create table with one column v containing the json

```sql
create or replace table raw_poi (v variant);
```

- copy the files into the table

```sql
COPY INTO RAW_POI
FROM @my_json_stage
ON_ERROR='skip_file';
```

### parquet stage

#### json stage

- create json format

```sql
CREATE OR REPLACE FILE FORMAT myparquetformat
	TYPE = parquet
	STRIP_OUTER_ARRAY = TRUE;
```

- create staging table

```sql
CREATE OR REPLACE STAGE my_parquet_stage
    FILE_FORMAT = myparquetformat;
```

- upload parquet files

```sql
Put file:///<path>*parquet @my_parquet_stage;
```

- create table

```sql
create or replace table raw_osm (
    osm_id int ,
    x double ,
    y double
  );
```

- copy the files into the table

```sql
copy into raw_osm
 from (select $1:osmid::int,
              $1:x::double,
              $1:y::double
      from @my_parquet_stage)
```

```mermaid
flowchart TB
    subgraph  id10 [Ingestion]
    id1>datatourisme.fr]-- Extract: Download from Website AS ZipStream --> id2{{Data Loader\nPOI'S AS JSON \n Map AS CSV}}
    id3>OpenstreetMaps]-- Extract: Download -->id2
    end
    subgraph id11 [ELT_DISTRIBUTED managed by Spark]
    id4(Objectstore: Minio)-->
    id5{{Spark \n Transform POI Data}}
    end
    subgraph id14 [ELT_LOCAL managed by DBT]
    id21(Local Store Bronze)-->
    id22{{DUCKDB \n Transform POI Data}}-->
    id23(Local Store Gold\nPOI data with nearest osmnx point)
    end
    id2 -- Ingest Data to Bronze Layer --> id11
    id2 -- Manual Ingest Data to Bronze Layer --> id14
    subgraph id12 [Modeling]
    id6(GraphDB: Neo4j) --> id7[API FastAPI]
    id8(SearchDB: ElasticSearch) --> id7
    end
    id11 -- Transform POI Location Data --> id6
    id11 -- Transform POI Search Data --> id8
    id14 -- Transform POI Location Data --> id6
    id14 -- Transform POI Search Data --> id8
    id6 -- Modeling --> id6
    id8 -- Modeling --> id8
    subgraph id13 [Serving]
    id9>FrontEnd: Dash / Leaflet]
    end
    id7 --> id9
```
