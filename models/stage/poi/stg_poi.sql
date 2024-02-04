{{ config(materialized='ephemeral') }}
with
    json as (
        select
            v:"@type" as types,
            v:"dc:identifier"::string as id,
            v:"rdfs:label".en[0]::string as label_en,
            v:"rdfs:label".fr[0]::string as label_fr,
            v:"hasDescription"[0]."shortDescription".en[0]::string as shortdescription,
            v:"hasDescription"[0]."dc:description".en[0]::string as description,
            v:"rdfs:comment".en[0]::string as comment,
            v:"isLocatedAt"[0]."schema:address"[0]."schema:addressLocality"::string
            as locality,
            v:"isLocatedAt"[0]."schema:address"[0]."schema:postalCode"::string
            as postal_code,
            v:"isLocatedAt"[0]."schema:address"[0]."schema:streetAddress"[0]::string
            as address,
            v:"isLocatedAt"[0]."schema:address"[
                0
            ]."hasAddressCity"."isPartOfDepartment"."rdfs:label".en[0]::string
            as department,
            v:"isLocatedAt"[0]."schema:geo"."schema:latitude"::float as latitude,
            v:"isLocatedAt"[0]."schema:geo"."schema:longitude"::float as longitude,
            v:"hasReview"[0]."hasReviewValue"."schema:ratingValue"::float as rating,
            v:"lastUpdateDatatourisme"::timestamp_tz as last_update
        from {{ source('POIFRANCE', 'poi') }}
    ),
    features as (
        select
            v:"dc:identifier"::string as id,
            array_agg(f.value:"rdfs:label".en[0]) as features
        from
            {{ source('POIFRANCE', 'poi') }},
            lateral flatten(input => v:"hasFeature"[0].features) f
        group by 1
    )
select
    to_array(j.types) as poi_types,
    j.id as poi_id,
    coalesce(j.label_en, j.label_fr) as poi_label,
    coalesce(j.description, j.shortdescription, j.comment) as poi_description,
    j.locality as poi_location_name,
    j.postal_code as poi_location_postal_code,
    j.address as poi_location_address,
    j.department as poi_department,
    j.latitude as poi_lat,
    j.longitude as poi_long,
    j.rating as poi_rating,
    f.features as poi_features,
    j.last_update as poi_last_update
from json j
left join features f on j.id = f.id
