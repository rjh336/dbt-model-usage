import json

TARGET_PATH = './integration_tests/target'


def get_run_results(target_path=TARGET_PATH):
    with open(f'{target_path}/run_results.json', 'r') as f:
        return json.load(f)


def test_build_success():
    """
    dbt build ran successfully 
    """
    run_results = get_run_results()
    statuses = [ r['status'] in ('pass', 'success') for r in run_results['results'] ]
    assert all(statuses)


def test_build_failure_all_tests():
    """
    dbt build failed all three dbt_model_usage tests
    """
    test_id = 'test.dbt_model_usage_integration_tests.dbt_model_usage_'
    run_results = get_run_results()
    error_results = [ r for r in run_results['results'] if r['status'] == 'error' ]
    fail_results = [ r for r in run_results['results'] if r['status'] == 'fail' ]
    test_results = [ r for r in fail_results if r['unique_id'].startswith(test_id) ]
    assert len(error_results) == 0
    assert len(fail_results) == 3
    assert len(test_results) == 3


def test_build_failure_column_test():
    """
    dbt build failed only the `dbt_model_usage_column_queried_within_last` test
    """
    test_id = 'test.dbt_model_usage_integration_tests.dbt_model_usage_column_queried_within_last'
    run_results = get_run_results()
    error_results = [ r for r in run_results['results'] if r['status'] == 'error' ]
    fail_results = [ r for r in run_results['results'] if r['status'] == 'fail' ]
    test_results = [ r for r in fail_results if r['unique_id'].startswith(test_id) ]
    assert len(error_results) == 0
    assert len(fail_results) == 1
    assert len(test_results) == 1