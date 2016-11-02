#!/bin/sh

docker run --name doorman-test-postgres \
    -e POSTGRES_PASSWORD=doorman -e POSTGRES_USER=doorman_test \
    -p 5433:5432 -d \
    postgres
