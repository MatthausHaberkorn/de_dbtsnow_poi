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
select
    {{ dbt_utils.generate_surrogate_key([
                'poi_label', 
                'poi_lat',
                'poi_long'
            ])
        }} as poi_key, * exclude row_num

from duplicates_removed
