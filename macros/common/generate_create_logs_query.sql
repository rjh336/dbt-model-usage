{% macro generate_create_logs_query(target_model, time_unit, num_units) %}

    {{ return(adapter.dispatch(
            'generate_create_logs_query', 
            'dbt_model_usage'
        )(target_model, time_unit, num_units)) }}

{% endmacro %}


{% macro bigquery__generate_create_logs_query(target_model, time_unit, num_units) %}

    {%- set query -%}
    
    -- If we saw the model created via a CREATE statement before the lookback period start, include it
    select
        query
    from
        `{{ target_model.database }}`.`region-{{ dbt_model_usage.get_current_bigquery_location() }}`.INFORMATION_SCHEMA.JOBS
    where 
        job_type = 'QUERY'
        and statement_type in (
            'CREATE_TABLE', 
            'CREATE_TABLE_AS_SELECT', 
            'CREATE_VIEW', 
            'CREATE_MATERIALIZED_VIEW',
            'MERGE'
        )
        and creation_time < timestamp_sub(current_timestamp(), interval {{ num_units }} {{ time_unit }})
        and destination_table.dataset_id = '{{ target_model.schema }}'
        and destination_table.table_id = '{{ target_model.name }}'
    
    union all
    
    -- Ensure we capture the model in case it was created further back than the information_schema.jobs
    -- retention period allows
    select
        ddl as query
    from
        `{{ target_model.database }}`.`{{ target_model.schema }}`.INFORMATION_SCHEMA.TABLES
    WHERE
        table_name = '{{ target_model.name }}'
        and creation_time < timestamp_sub(current_timestamp(), interval {{ num_units }} {{ time_unit }})
    
    {%- endset -%}

    {{ return(query) }}

{% endmacro %}


{% macro snowflake__generate_create_logs_query(target_model, time_unit, num_units) %}

    {%- set query -%}
    
    -- If we saw the model created before lookback period start, include it
    -- Note: This wont give us tables created in the last 90 minutes
    select
        table_name
    from
        snowflake.account_usage.tables
    where 
        created < timestampadd({{ time_unit }}, -{{ num_units }}, current_timestamp())
        and lower(table_name) = lower('{{ target_model.name }}')
        and lower(table_schema) = lower('{{ target_model.schema }}')
        and lower(table_catalog) = lower('{{ target_model.database }}')
    
    union all

    -- Ensure we capture the model (as a TABLE) in case it was created further back than 
    -- the ACCOUNT_USAGE.TABLES retention period or within 90 minutes of now
    select
        table_name
    from
        {{ target_model.database }}.information_schema.table_storage_metrics
    where 
        table_created < timestampadd({{ time_unit }}, -{{ num_units }}, current_timestamp())
        and lower(table_name) = lower('{{ target_model.name }}')
        and lower(table_schema) = lower('{{ target_model.schema }}')
        and lower(table_catalog) = lower('{{ target_model.database }}')

    union all
    
    -- Ensure we capture the model (as a VIEW) in case it was created further back than 
    -- the ACCOUNT_USAGE.VIEWS retention period or within 90 minutes of now
    select
        table_name
    from
        {{ target_model.database }}.information_schema.views
    where 
        created < timestampadd({{ time_unit }}, -{{ num_units }}, current_timestamp())
        and lower(table_name) = lower('{{ target_model.name }}')
        and lower(table_schema) = lower('{{ target_model.schema }}')
        and lower(table_catalog) = lower('{{ target_model.database }}')
    
    {%- endset -%}

    {{ return(query) }}

{% endmacro %}