#!/bin/sh

echo "Content-type: text/plain; charset=utf-8"
echo "Connection: close"
echo ""

echo $QUERY_STRING
XX=$(echo "$QUERY_STRING" | sed -n 's/^.*val_x=\([^&]*\).*$/\1/p')
YY=$(echo "$QUERY_STRING" | sed -n 's/^.*val_y=\([^&]*\).*$/\1/p')
echo "val_x = $XX"
echo "val_y = $YY"
echo "Bye."
