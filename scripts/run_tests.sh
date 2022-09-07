#!/bin/sh

dbt_target=$1

printf "dbt build ...\n"
dbt build -t $dbt_target --project-dir $DBT_PROJECT_DIR --full-refresh --vars '{time_unit: day, num_units: 90}'
pytest -v scripts/test_run_results.py::test_build_success

printf "\n\nSleeping for 10 seconds ..."
sleep 10

printf "\n\ndbt test ...\n"
dbt test -t $dbt_target --project-dir $DBT_PROJECT_DIR --vars '{time_unit: second, num_units: 5}' || true
printf "\nRun results validation:\n"
pytest -v ./scripts/test_run_results.py::test_build_failure_all_tests

printf "\n\nRunning integration test query:"
python3 ./scripts/query_database.py $dbt_target models_query

printf "\n\ndbt test ...\n"
dbt test -t $dbt_target --project-dir $DBT_PROJECT_DIR --vars '{time_unit: second, num_units: 60}' || true
printf "\nRun results validation:\n"
pytest -v scripts/test_run_results.py::test_build_failure_column_test

printf "\n\nRunning integration test query:"
python3 ./scripts/query_database.py $dbt_target columns_query

printf "\n\ndbt test ...\n"
dbt test -t $dbt_target --project-dir $DBT_PROJECT_DIR --vars '{time_unit: hour, num_units: 1}'
printf "\nRun results validation:\n"
pytest -v scripts/test_run_results.py::test_build_success