{{ config(materialized='ephemeral') }}
with
    filtered_raw_antology as (
        select
            split_part(r.v:"@id"::string, '#', -1) as poi_type_key,
            array_agg(
                case
                    when position('#' in f.value:"@id"::string) > 0
                    then split_part(f.value:"@id"::string, '#', -1)
                    when position('/' in f.value:"@id"::string) > 0
                    then split_part(f.value:"@id"::string, '/', -1)
                    when position('_:' in f.value:"@id"::string) = 1
                    then null
                    else f.value:"@id"::string
                end
            ) as poi_type_classes
        from
            {{ source('POIFRANCE', 'ontology') }} r,
            lateral flatten(
                input => r.v:"http://www.w3.org/2000/01/rdf-schema#subClassOf"
            ) f
        where poi_type_key in (select poi_type from {{ ref("mrt_poi_types") }})
        group by poi_type_key
    )
select *
from filtered_raw_antology
order by poi_type_key
