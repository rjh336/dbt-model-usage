# dbt Model Usage - Integration Tests

## Setup

From the [project root directory](..):

1. Set/export the environment variables in [.env.sample](.env.sample)

2. Create a `profiles.yml`
    ```sh
    cp integration_tests/ci/sample.profiles.yml integration_tests/ci/profiles.yml
    ```

3. Create development environment and install dependencies
    ```sh
    python3 -m venv venv
    . venv/bin/activate
    pip install -U pip setuptools wheel
    pip install -r dev-requirements.txt
    dbt deps --project-dir $DBT_PROJECT_DIR
    ```

4. Verify that the `integration_tests/dbt_packages/dbt_model_usage` directory was created.

5. Execute tests for a given dbt target:
    ```sh
    $SHELL -e scripts/run_tests.sh [target-name]
    ```