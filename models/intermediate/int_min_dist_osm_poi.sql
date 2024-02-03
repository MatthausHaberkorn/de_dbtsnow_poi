{{ config(materialized='table') }}

with
    distance as (
        select
            osm.osm_id,
            poi.poi_key,
            st_distance(
                st_makepoint(osm.x, osm.y), st_makepoint(poi.poi_long, poi.poi_lat)
            ) as distance
        from {{ source('POIFRANCE', 'osm') }} as osm
        join {{ ref("stg_poi_cleansed") }} as poi on osm.department = poi.poi_department

    ),
    ranked_distance as (
        select
            osm_id,
            poi_key,
            distance,
            row_number() over (partition by poi_key order by distance) as rank
        from distance
        qualify rank = 1
    )

select osm_id, poi_id, distance
from ranked_distance
