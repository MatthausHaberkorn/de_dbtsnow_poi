with
    pois as (
        select * exclude(poi_features, poi_types) from {{ ref("stg_poi_cleansed") }}
    ),
    distance as (select * from {{ ref("int_min_dist_osm_poi") }})
select p.*, d.* exclude poi_key
from pois as p
join distance as d on p.poi_key = d.poi_key
