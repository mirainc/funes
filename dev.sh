#!/bin/sh

# run compose
docker-compose kill
docker-compose -f docker-compose.yml build # --no-cache
docker-compose -f docker-compose.yml up
