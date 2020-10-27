#!/bin/bash

echo "Content-type: text/plain"
echo ""

if [ "$REQUEST_METHOD" = "POST" ]; then
	if [ "$CONTENT_LENGTH" -gt 0 ]; then
		read -t 5 post_data
		echo -e $(date +%s) "$post_data" #>>/tmp/postdata.tmp
	fi

	exit 0
fi

echo 'Perform a POST request to this page.'
