with
    pois as (
        select * except poi_features, poi_types from {{ ref("stg_poi_cleansed") }}
    ),
    distance as (select * from {{ ref("stg_distance") }})
select *
from pois as p
join distance as d on p.poi_key = d.poi_key
