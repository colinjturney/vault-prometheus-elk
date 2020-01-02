#!/bin/bash

SECONDS=0
START=$(date)
for i in {1..10000};do
  vault kv get secret/hello${i}
done
END=$(date)

echo "Started: ${START} - Ended: ${END} - Secs: ${SECONDS}"
