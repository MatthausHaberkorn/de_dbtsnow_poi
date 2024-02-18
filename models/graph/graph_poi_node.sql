with
    poi_node as (
        select
            poi_key as "POI_KEY:ID",
            poi_label as name,
            replace(poi_description, '"', '') as description,
            concat_ws(
                ' ', poi_location_name, poi_location_postal_code, poi_location_address
            ) as address,
            poi_lat as lat,
            poi_long as long,
            poi_department as department,
            concat(
                regexp_replace(array_to_string(poi_types, '|'), 'schema:', ''),
                '|',
                poi_department
            ) as ":LABEL"

        from {{ ref("mrt_pois") }}
    )
select *
from poi_node
