#!/bin/sh

# run compose
docker-compose kill
docker-compose -f docker-compose.yml up
