#!/bin/bash

CACHE_AGE_MIN=$1
CACHE_DIR=$2

if [ -z "$CACHE_AGE_MIN" ]; then
    CACHE_AGE_MIN=1440		# 24hrs
    echo "Using default CACHE_AGE_MIN: $CACHE_AGE_MIN"
fi
if [ -z "$CACHE_DIR" ]; then
    CACHE_DIR=/data/funes/cert_cache
    echo "Using default CACHE_DIR: $CACHE_DIR"
fi

# Delete all cert cache files older than cache age param.
find $CACHE_DIR -mindepth 1 -mmin +$CACHE_AGE_MIN -print -delete
