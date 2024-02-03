with
    bridge as (
        select p.poi_key, t.poi_type_key
        from {{ ref('stg_poi_cleansed') }} as p
        join
            {{ ref('mrt_poi_types') }} as t
            on array_contains(t.poi_type::array, p.poi_types)
    )

select *
from bridge
