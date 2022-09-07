{% test column_queried_within_last(model, column_name, time_unit, num_units, threshold=1) %}
    {{ 
        return(
            adapter.dispatch(
                'test_column_queried_within_last', 
                'dbt_model_usage'
            )(model, column_name, time_unit, num_units, threshold)
        )
    }}
{% endtest %}


{% macro default__test_column_queried_within_last(model, column_name, time_unit, num_units, threshold) -%}

with select_queries as (
    select count(*) as select_query_count from (
        {{ dbt_model_usage.generate_select_logs_query(model, time_unit, num_units) }}
        {{ dbt_model_usage.generate_column_filter(column_name) }}
    )
),

create_queries as (
    select count(*) as create_query_count from (
        {{ dbt_model_usage.generate_create_logs_query(model, time_unit, num_units) }}
    )
)

select *
from select_queries
cross join create_queries

where
    create_query_count > 0
    and select_query_count < {{ threshold }}

{%- endmacro %}