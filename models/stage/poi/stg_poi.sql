with
    json as (

        select
            v:"@type" as types,
            v:"dc:identifier"::string as id,
            v:"rdfs:label".en[0]::string as label_en,
            v:"rdfs:label".fr[0]::string as label_fr,
            v:"hasDescription"[0].shortdescription.en[0]::string as shortdescription,
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
            ].hasaddresscity.ispartofdepartment."rdfs:label".en[0]::string
            as department,
            v:"isLocatedAt"[0]."schema:geo"."schema:latitude"::float latitude,
            v:"isLocatedAt"[0]."schema:geo"."schema:longitude"::float longitude,
            v:"hasReview"[0].hasreviewvalue."schema:ratingValue" as rating,
            v:"hasFeature"[0].features[0]."rdfs:label".en[0] as feature_1,
            v:"hasFeature"[0].features[1]."rdfs:label".en[0] as feature_2,
            v:"hasFeature"[0].features[2]."rdfs:label".en[0] as feature_3,
            v:"hasFeature"[0].features[3]."rdfs:label".en[0] as feature_4

        from {{ source('POIFRANCE', 'poi') }}

    )
select
    array_to_string(types, ', ') as poi_types,
    id as poi_id,
    coalesce(label_en, label_fr) as poi_label,
    coalesce(description, shortdescription, comment) as poi_description,
    locality as poi_location_name,
    postal_code as poi_location_postal_code,
    address as poi_location_address,
    department as poi_department,
    latitude as poi_lat,
    longitude as poi_long,
    rating as poi_rating,
    concat_ws(', ', feature_1, feature_2, feature_3, feature_4) as poi_features

from json
