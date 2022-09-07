{% macro get_current_bigquery_location() %}

    {{ return(adapter.dispatch('get_current_bigquery_location', 'dbt_model_usage')()) }}

{% endmacro %}


{% macro default__get_current_bigquery_location() %}

    {% set location = dbt_model_usage.get_var('model_usage_bigquery_location')|trim|lower %}

    {% if location not in dbt_model_usage.get_var('model_usage_bigquery_locations') %}
        {{ exceptions.raise_compiler_error(
            'BigQuery usage tests require a valid location. Set the variable `model_usage_bigquery_location` in your dbt_project.yml')
        }}
    {% endif %}

    {{ return(location) }}

{% endmacro %}