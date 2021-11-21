#!/bin/sh
#
# Script to retrieve sensor measurements as CSV.
# It uses rec2csv to convert recfiles in the data directory into a CSV data
# stream.
# Accepts the following GET parameters:
#	name      - (mandatory) name of the node for which the data is queried
#	timestamp - oldest timestamp to retrieve. Defaults to 0

# Directory containing recfiles
DATA_DIR='/srv/http/iot.pielluzza.ts/data'

echo "Content-type: text/plain; charset=utf-8"
echo "Connection: close"
echo ""

# with printf '%q' any character that would, in other circumstances, cause code
# to be executed, gets escaped into a safe version that cannot be used to
# execute code.
name=$(printf '%q' $QUERY_STRING | sed -n 's/^.*name=\([^\&]*\).*$/\1/p')
ts=$(printf '%q' $QUERY_STRING | sed -n 's/^.*timestamp=\([^\&]*\).*$/\1/p')

recsel -e "timestamp >= $ts" "$DATA_DIR/$name.csv.rec" | rec2csv
