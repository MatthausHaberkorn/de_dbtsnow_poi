with
    types as (
        select distinct flattened.value::string as poi_type
        from
            {{ ref("stg_poi_cleansed") }},
            lateral flatten(input => poi_types) as flattened
    )

select
    {{ dbt_utils.generate_surrogate_key([
                'poi_type'
            ])
        }} as poi_type_key, poi_type
from types
