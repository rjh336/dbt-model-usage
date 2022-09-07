{% macro generate_select_logs_query(target_model, time_unit, num_units) %}

    {{ return(adapter.dispatch(
            'generate_select_logs_query', 
            'dbt_model_usage'
        )(target_model, time_unit, num_units)) }}

{% endmacro %}


{% macro bigquery__generate_select_logs_query(target_model, time_unit, num_units) %}

    {%- set query_comment_pattern = dbt_model_usage.get_var('model_usage_dbt_query_comment_pattern') -%}
    
    {%- set query -%}

    select
        query
    from
        `{{ target_model.database }}`.`region-{{ dbt_model_usage.get_current_bigquery_location() }}`.INFORMATION_SCHEMA.JOBS
    where 
        job_type = 'QUERY'
        and statement_type = 'SELECT'
        and creation_time between timestamp_sub(current_timestamp(), interval {{ num_units }} {{ time_unit }}) and current_timestamp()
        and regexp_contains(query, r'{{ target_model.schema }}`?\.`?{{ target_model.name }}')
        {%- if query_comment_pattern|as_bool %}
        and not regexp_contains(query, r'{{ query_comment_pattern }}')
        {% endif -%}
        
    {%- endset -%}
    
    {{ return(query) }}

{% endmacro %}


{% macro snowflake__generate_select_logs_query(target_model, time_unit, num_units) %}

    {%- set query_tag_pattern = dbt_model_usage.get_var('model_usage_dbt_query_tag_pattern') -%}
    
    {%- set query -%}
    
    -- ACCOUNT_USAGE.QUERY_HISTORY can grab queries up to one year old, but it can take
    -- a query up to 45 minutes to make it into this table. See more info:
    -- https://docs.snowflake.com/en/sql-reference/account-usage/query_history.html
    with account_usage_queries as (
        select
            query_id,
            query_text
        from
            snowflake.account_usage.query_history
        where
            query_type = 'SELECT'
            and start_time between timestampadd({{ time_unit }}, -{{ num_units }}, current_timestamp()) and current_timestamp()
            and regexp_like(query_text, '.*{{ target_model.schema }}[\"\']?\.[\"\']?{{ target_model.name }}.*', 'si')
            {%- if query_tag_pattern|as_bool %}
            and not regexp_like(query_tag, '{{ query_tag_pattern }}')
            {% endif -%}
    ),
    
    -- INFORMATION_SCHEMA.QUERY_HISTORY can grab queries up to 7 days old, and reflects 
    -- queries as soon as they are executed by Snowflake. See more info:
    -- https://docs.snowflake.com/en/sql-reference/functions/query_history.html
    information_schema_queries as (
        select
            query_id,
            query_text
        from
            table(dbt_model_usage.information_schema.query_history(result_limit => 10000))
        where
            query_type = 'SELECT'
            and start_time between timestampadd({{ time_unit }}, -{{ num_units }}, current_timestamp()) and current_timestamp()
            and regexp_like(query_text, '.*{{ target_model.schema }}[\"\']?\.[\"\']?{{ target_model.name }}.*', 'si')
            {%- if query_tag_pattern|as_bool %}
            and not regexp_like(query_tag, '{{ query_tag_pattern }}')
            {% endif -%}
    )

    -- ONLY COUNT EACH QUERY ONCE
    select * from (
        select query_id, query_text from account_usage_queries 
        union
        select query_id, query_text from information_schema_queries 
    )
    {%- endset -%}

    {{ return(query) }}

{% endmacro %}