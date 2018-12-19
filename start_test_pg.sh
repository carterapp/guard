#!/bin/sh
name="doorman-test-postgres"

if [ "$1" == "clean" ]; then
    docker stop $name
    docker rm $name
fi

docker run --name $name \
    -e POSTGRES_PASSWORD=doorman -e POSTGRES_USER=doorman_test \
    -p 5433:5432 -d \
    postgres
