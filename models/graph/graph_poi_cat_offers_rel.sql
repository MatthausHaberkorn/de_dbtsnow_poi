with
    offers_relation as (
        select poi_key as ":START_ID", poi_type as ":END_ID", 'OFFERS' as ":TYPE"
        from poifrance.dev.mrt_bridge_poi_types
    )
select *
from offers_relation
