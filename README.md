# dbt Model Usage
This [dbt](https://docs.getdbt.com/) package provides tests to let you know whether your models are still relevant to your users. These tests scan your database's query logs to check if users are still SELECTing from the tables dbt produces. Test failures can let you know when it might be time to retire unused models.

<br>

# Database Support
This package currently supports Google BigQuery and Snowflake.

<br>

# Installation
1. Add this package to your project's `packages.yml`
    ```yaml
    packages:
      - package: rjh336/dbt-model-usage
        version: 0.1.2
    ```
2. Update dependencies in your project
    ```bash
    $ dbt deps
    ```

<br>

# Setup

## In your project
You can configure this package via the [vars](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-variables) config in your `dbt_project.yml`

```yaml
# dbt_project.yml

vars:
  # BIGQUERY ONLY:
  model_usage_dbt_query_comment_pattern: 'my-custom-query-comment-regex'

  # SNOWFLAKE ONLY:
  model_usage_dbt_query_tag_pattern: 'my-custom-query-tag-regex'
```

- `model_usage_dbt_query_comment_pattern`: Regular expression string used to find and EXCLUDE queries executed by dbt via the [query-comment](https://docs.getdbt.com/reference/project-configs/query-comment). Normally we would not consider these queries as 'user' queries since they might run every time models are built (e.g. tests and hooks).  By default, this value is set to **`^\/\*\s+\{"app"\:\s+"dbt".*`**.  If your project uses a custom query-comment you might want to use your own pattern. If you prefer to count dbt-generated queries in your tests to indicate a model's relevance, then set this variable to ''.

- `model_usage_dbt_query_tag_pattern`: Regular expression string used to find and EXCLUDE queries executed by dbt via the [query_tag](https://docs.getdbt.com/reference/warehouse-profiles/snowflake-profile#query_tag). If this variable is not defined then tagged queries will count as relevant user SELECT statements in the test results.

## Required Permissions
### BigQuery
Since the BigQuery implementation of these tests will query from the [INFORMATION_SCHEMA.JOBS](https://cloud.google.com/bigquery/docs/information-schema-jobs) view, the Google Cloud user referenced in your `profiles.yml` must include the IAM permission `bigquery.jobs.listAll`.

### Snowflake
dbt must have permission to query from the [Account Usage](https://docs.snowflake.com/en/sql-reference/account-usage.html#account-usage-views) and [Information Schema](https://docs.snowflake.com/en/sql-reference/info-schema.html) views.

<br>

# Available Tests

**model_queried_within_last**

Asserts that the target model has  been queried by your users within a defined lookback time period, AND that the model was created at some point before the lookback period start time. "User queries" are defined as `SELECT` statements that were not executed by dbt.

*Args*:
- `num_units` - [REQUIRED] Number of time units to look back from current time.
- `time_unit` - [REQUIRED] The unit of time used for the lookback period. Can be one of: "day" | "hour" | "minute" | "second".
- `threshold` - [OPTIONAL] If the model's user query count within the lookback period is below this number, the test fails. Default value is 1.

*Limitations*:
- **BigQuery**: query jobs are retained for [up to 180 days](https://cloud.google.com/bigquery/docs/information-schema-jobs#data_retention), so setting a lookback period greater than 180 days is not supported.
- **Snowflake**: account query history is retained for [up to 1 year](https://docs.snowflake.com/en/sql-reference/account-usage.html#account-usage-views), so setting a lookback period greater than 365 days is not supported.

*Usage*:
```yaml
# properties.yml

version: 2

models:
  - name: some_model
    tests:
      - dbt_model_usage.model_queried_within_last:
          num_units: 30
          time_unit: day
          threshold: 1
```
*^ This example fails if some_model was created at some point earlier than 30 days ago, AND there have been fewer than 1 user queries referencing some_model in the last 30 days.*

<br>

**column_queried_within_last**

Asserts that the column in the target model has been directly referenced in your users' queries within a defined lookback time period, AND that the target model was created at some point before the lookback period start time. "User queries" are defined as `SELECT` statements that were not executed by dbt.

*Args*:
- `num_units` - [REQUIRED] Number of time units to lookback from current time.
- `time_unit` - [REQUIRED] The unit of time used for the lookback period. Can be one of: "day" | "hour" | "minute" | "second".
- `threshold` - [OPTIONAL] If the column's user query count within the lookback period is below this number, the test fails. Default value is 1.

*Limitations*: same as for [model_queried_within_last](#model_queried_within_last)

*Usage*:
```yaml
version: 2

models:
  - name: some_model
    columns:
      - name: some_column
        tests:
          - dbt_model_usage.column_queried_within_last:
              num_units: 10
              time_unit: day
              threshold: 1
```
*^ This example fails if some_model was created at some point earlier than 10 days ago, AND there have been fewer than 1 user queries referencing some_model.some_column in the last 10 days.*
