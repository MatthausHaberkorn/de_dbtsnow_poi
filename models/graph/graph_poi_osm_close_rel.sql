with
    close_to_rel as (
        select
            poi_key as ":START_ID",
            osm_id as ":END_ID",
            'CLOSE_TO' as ":TYPE",
            distance as "DISTANCE_M:FLOAT",
            (distance * 60) / 5000 as "DURATION_MIN:FLOAT"
        from {{ ref("mrt_pois") }}

    )
select *
from close_to_rel
