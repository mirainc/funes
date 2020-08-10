#!/bin/bash

set -e

for i in $LOG_DIR/*; do cat /dev/null > $i; done
