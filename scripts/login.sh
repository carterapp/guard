#!/bin/sh
user=$1
pass=$2
host=localhost:4000
curl -H 'content-type: application/json' localhost:4000/api/doorman/session -d '{"session": {"email": "'$user'", "password": "'$pass'"}}' | json_pp
