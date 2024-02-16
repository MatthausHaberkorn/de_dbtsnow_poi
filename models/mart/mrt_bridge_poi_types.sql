with
    bridge as (
        select p.poi_key, t.new_type as poi_type
        from {{ ref('stg_poi_cleansed') }} as p
        join
            {{ source('RAW_TYPES_MAPPING', 'types_resource') }} as t
            on array_contains(t.data_gov_type::variant, p.poi_types)
        qualify
            row_number() over (partition by p.poi_key, t.new_type order by p.poi_key)
            = 1
    )

select *
from bridge
