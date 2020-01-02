#!/bin/bash

SECONDS=0
START=$(date)
for i in {1..10000};do
  vault kv put secret/hello${i} value=12345
done
END=$(date)

echo "Started: ${START} - Ended: ${END} - Secs: ${SECONDS}"
