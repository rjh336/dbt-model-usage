{% macro generate_column_filter(column_name) %}

  {{ return(adapter.dispatch('generate_column_filter', 'dbt_model_usage')(column_name)) }}

{% endmacro %}


{% macro bigquery__generate_column_filter(column_name) %}

    {%- set filter_condition -%}

    and lower(query) like '%{{ column_name|lower|trim }}%'
    
    {%- endset -%}

    {{ return(filter_condition) }}

{% endmacro %}


{% macro snowflake__generate_column_filter(column_name) %}

    {%- set filter_condition -%}

    where lower(query_text) like '%{{ column_name|lower|trim }}%'
    
    {%- endset -%}

    {{ return(filter_condition) }}

{% endmacro %}