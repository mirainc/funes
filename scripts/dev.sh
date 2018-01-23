#!/bin/sh

eval $(docker-machine env)

# run compose
docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up
