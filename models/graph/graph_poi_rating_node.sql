with
    rating_rel as (
        select
            poi_key as ":START_ID",
            'REVIEW' as ":END_ID",
            'HAS_FIVE_SCALE_RATING' as ":TYPE",
            poi_rating as value
        from {{ ref("mrt_pois") }}
        where poi_rating is not null
    )
select *
from rating_rel
