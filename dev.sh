#!/bin/sh

# run compose
docker-compose kill
docker-compose up --no-color 2>&1 | sed 's/^[^ ]*  *| //'
