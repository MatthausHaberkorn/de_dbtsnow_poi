with
    types as (
        select distinct flattened.value::string as type
        from
            {{ ref("stg_poi_cleansed") }},
            lateral flatten(input => poi_types) as flattened
    )

select row_number() over (order by type) as type_surrogate_key, type
from types
