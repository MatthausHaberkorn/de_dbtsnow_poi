with
    bridge as (
        select p.poi_key, t.poi_feature_key
        from {{ ref('stg_poi_cleansed') }} as p
        join
            {{ ref('mrt_poi_features') }} as t
            on array_contains(t.poi_feature::variant, p.poi_features)
    )

select *
from bridge
