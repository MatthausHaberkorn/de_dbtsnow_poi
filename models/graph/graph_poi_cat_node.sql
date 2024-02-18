with
    category_node as (
        select
            new_type as "TYPE:ID",
            regexp_replace(
                array_to_string(array_agg(data_gov_type), '|'), 'schema:', ''
            ) as ":LABEL"
        from {{ source('RAW_TYPES_MAPPING', 'types_resource') }}
        group by new_type

    )
select *
from category_node
