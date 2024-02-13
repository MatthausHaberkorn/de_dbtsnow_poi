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
  PASSWORD='<pwd>'
  LOGIN_NAME='<user>'
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
    y double,
    department string
  );
```

- copy the files into the table

```sql
copy into raw_osm
 from (select $1:osmid::int,
              $1:x::double,
              $1:y::double,
              $1:location_department::string
      from @my_parquet_stage);
```

## Project data flow

- following flowchart shows the plans for the data flow / lineage

```mermaid
flowchart TB
    subgraph  id10 [Ingestion]
        id1>datatourisme.fr]-- Extract\nDownload from Website --> id2{{Data Loader\nPOI'S AS JSON \n Map AS CSV}}
        id3>OpenstreetMaps]-- Extract\n Download via osmnx -->id2
    end

    subgraph id14 [ELT: Warehouse - Snowflake]
    direction TB
        id21(File store - Snowflake Stages\n POI: MY_JSON_STAGE\n OSM: MY_PARQUET_STAGE)--Copy Table\nExecution Snowflake-->
        id31(Snowflake Raw Tables as DBT sources\n POI: RAW_POI\n OSM: RAW_OSM)--Pipeline run: DBT\n Execution: Snowflake  -->
        id22{{DBT Extractions \n POI: extract and validate data from json }}--Pipeline run: DBT\n Execution: Snowflake  -->
        id23{{DBT Transformations\n Enrichment of POI data with nearest OSM junction}}
    end

    id2 -- Manual Ingest into Snowflake Staging\n via SnowSQL --> id14
    subgraph id12 [Backend]
        id6(GraphDB: Neo4j) --> id7[API FastAPI]
        id8(SearchDB: ElasticSearch) --> id7
    end

    id14 -- Load POI Location Data\n Via Python Connector --> id6
    id14 -- Load POI Text search Data\n Via Python Connector  --> id8
    id6 -- Modeling --> id6
    id8 -- Modeling --> id8
    subgraph id13 [Serving]
        id9>FrontEnd: Dash / Leaflet]
    end
    id12 --> id13

classDef myClass stroke:#ffa500,stroke-width:2px;
class id1,id2,id3,id21,id22,id23,id6,id7,id31 myClass;
```

### POI Ontology

```mermaid
flowchart LR
    id1{{POI\n -Label-\n -Description-}} -- CLOSE_TO --> id2{{OSM Junction\n -osm_id-}}
    id1 -- is_located_in --> id3{{Department\n-Name-}}
    id1 -- has_address\n street_num --> id4{{Location\n-City-}}
    id1 -- has_rating --> id5{{5 Star}}
    id1 -- offers --> id6{{Features}}
    id1 -- is_a --> id7{{Type}}

```
