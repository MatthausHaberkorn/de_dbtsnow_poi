with
    bridge as (
        select p.poi_surrogate_key, t.poi_type_surrogate_key
        from {{ ref('stg_poi_cleansed') }} as p
        join {{ ref('int_poi_types') }} as t on array_contains(p.poi_types, t.poi_type)
    )

select *
from bridge
