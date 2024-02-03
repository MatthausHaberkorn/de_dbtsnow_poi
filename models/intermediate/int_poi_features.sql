with
    features as (
        select distinct flattened.value::string as feature
        from
            {{ ref("stg_poi_cleansed") }},
            lateral flatten(input => poi_features) as flattened
    )

select row_number() over (order by feature) as feature_surrogate_key, feature
from features
