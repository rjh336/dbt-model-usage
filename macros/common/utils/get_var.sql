{% macro get_var(var_name) %}
  
  {# Return the global variable value if set by user. If that is 
    not set, default to the value in default_config #}

  {{ return(adapter.dispatch('get_var', 'dbt_model_usage')(var_name)) }}

{% endmacro %}


{% macro bigquery__get_var(var_name) %}

  {% set default_config = {
    'model_usage_dbt_query_comment_pattern': '^\/\*\s+\{"app"\:\s+"dbt".*',
    'model_usage_bigquery_location': target.location,
    'model_usage_bigquery_locations': [
        'us',
        'eu',
        'us-central1',
        'us-east1',
        'us-east4',
        'us-west1',
        'us-west2',
        'us-west3',
        'us-west4',
        'southamerica-east1',
        'southamerica-west1',
        'northamerica-northeast1',
        'northamerica-northeast2',
        'asia-east1',
        'asia-east2',
        'asia-south1',
        'asia-south2',
        'asia-northeast1',
        'asia-northeast2',
        'asia-northeast3',
        'asia-southeast1',
        'asia-southeast2',
        'australia-southeast1',
        'australia-southeast2',
        'europe-west1',
        'europe-west2',
        'europe-west3',
        'europe-west4',
        'europe-west6',
        'europe-north1'
    ]
  } %}

  {{ return( var(var_name, default_config.get(var_name)) ) }}

{% endmacro %}


{% macro snowflake__get_var(var_name) %}

  {% set default_config = {
    'model_usage_dbt_query_tag_pattern': target.query_tag
  } %}

  {{ return( var(var_name, default_config.get(var_name)) ) }}

{% endmacro %}