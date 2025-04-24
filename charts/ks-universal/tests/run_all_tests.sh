#!/bin/bash

# Run all tests in the tests directory
echo "Running all tests..."
cd "$(dirname "$0")/.."
helm unittest . --file 'tests/deployment_test.yaml' \
               --file 'tests/ingress_test.yaml' \
               --file 'tests/service_test.yaml' \
               --file 'tests/job_and_cronjob_test.yaml' \
               --file 'tests/configs_test.yaml' \
               --file 'tests/dex_test.yaml' \
               --file 'tests/certificate_test.yaml' \
               --file 'tests/autocreate_test.yaml'

if [ $? -eq 0 ]; then
    echo "All tests passed successfully!"
else
    echo "Some tests failed!"
fi 