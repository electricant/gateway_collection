#!/bin/bash

echo "Content-type: text/csv"
echo 'Content-Disposition: attachment; filename="thdata.csv"'
echo ""

cat /tmp/postdata.tmp | awk -f postdata2csv.awk
