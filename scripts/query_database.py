from dotenv import load_dotenv
load_dotenv()
import os
import sys
import snowflake.connector
from google.cloud import bigquery

QUERIES = {
    'models_query': """
        select * from {0}.{1}.test_model_view_{2}
        union all
        select * from {0}.{1}.test_model_table_{2}
        """,

    'columns_query': """
        select string_field 
        from {0}.{1}.test_model_view_{2}
        """
}


def main(target, query_name):
    query_format_string = QUERIES[query_name]

    if target == 'bigquery':
        bigquery_ctx = bigquery.Client()
        query = query_format_string.format(
            os.getenv('BIGQUERY_TEST_DATABASE'),
            os.getenv('TEST_SCHEMA'),
            os.getenv('GLOBAL_MODEL_SUFFIX')
        )
        print(f"{query}\n")
        _ = bigquery_ctx.query(query).result()
    
    if target == 'snowflake':
        snowflake_ctx = snowflake.connector.connect(
            user=os.getenv('SNOWFLAKE_USERNAME'),
            password=os.getenv('SNOWFLAKE_PASSWORD'),
            account=os.getenv('SNOWFLAKE_ACCOUNT_ID'))
        query = query_format_string.format(
            os.getenv('SNOWFLAKE_TEST_DATABASE'),
            os.getenv('TEST_SCHEMA'),
            os.getenv('GLOBAL_MODEL_SUFFIX')
        )
        print(f"{query}\n")
        cur = snowflake_ctx.cursor()
        cur.execute(query)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])