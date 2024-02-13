{{ config(materialized='table') }}
with
    valid_lat_long as (
        select *
        from {{ ref("stg_poi") }}
        where
            poi_lat is not null
            and poi_long is not null
            and poi_lat between 41 and 51
            and poi_long between -5 and 10
    ),
    dedup as (
        select *
        from valid_lat_long
        qualify
            row_number() over (
                partition by poi_id, poi_lat, poi_long order by poi_last_update asc
            )
            = 1
    )
select *
from dedup
