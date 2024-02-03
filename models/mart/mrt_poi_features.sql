with
    features as (
        select distinct flattened.value::string as poi_feature
        from
            {{ ref("stg_poi_cleansed") }},
            lateral flatten(input => poi_features) as flattened
    )

select
    {{ dbt_utils.generate_surrogate_key([
                'poi_feature'
            ])
        }} as poi_feature_key, poi_feature
from features
