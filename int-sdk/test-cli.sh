#!/bin/bash

# execute tests
printheader "EXECUTE SON-CLI INTEGRATION TESTS"
docker exec son-cli-int-test /bin/bash -c 'cd /tests; ./run-test-cli.sh'
