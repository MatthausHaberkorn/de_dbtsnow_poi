{{ config(materialized='table') }}
with
    duplicates_removed as (
        select
            *,
            row_number() over (
                partition by poi_id, poi_lat, poi_long order by poi_last_update asc
            ) as row_num
        from {{ ref("stg_poi") }}
        qualify row_num = 1
    )
select * exclude row_num, row_number() over (order by poi_id) as poi_key

from duplicates_removed
