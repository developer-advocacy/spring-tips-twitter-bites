#!/usr/bin/env bash
set -e
set -o pipefail
HOST=$1
INPUT_FN=$1
OUTPUT_FN="${INPUT_FN}.jpg"
curl -u ${SPRING_TIPS_BITES_USERNAME}:${SPRING_TIPS_BITES_PASSWORD} -v  -XPOST -H "Content-Type: application/octet-stream"  --data-binary @"${INPUT_FN}"  http://${HOST}/tips/preview --output "${OUTPUT_FN}"
open $OUTPUT_FN