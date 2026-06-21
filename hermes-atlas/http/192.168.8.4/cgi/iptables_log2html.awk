BEGIN { i = 1; }
{
	a[i] = $0;

	# The first item in dmesg -T is always a timestamp.
	#tstamp[i] = $1 " " $2 " " $3 " " $4 "]";
	tstamp[i] = $2 " " $3 " " $4;

	split($0, tokens, " "); # I'd like to know the total nr. of tokens
	
	# This loop starts from 7 since we want to skip the first two elements
	# as they are timestamp and log identifier
	for (tk_i = 7; tk_i < length(tokens); tk_i++) {
		split(tokens[tk_i], keyval, "="); # split key & value pairs

		if(length(keyval) < 2) # Nothing to split: we have a parameter
			params[i] = params[i] keyval[1] " "
		else if (keyval[1] == "IN")
			inp[i] = keyval[2]
		else if (keyval[1] == "OUT")
			oup[i] = keyval[2]
		else if (keyval[1] == "SRC")
			src[i] = keyval[2]
		else if (keyval[1] == "DST")
			dst[i] = keyval[2]
		else if (keyval[1] == "LEN")
			len[i] = keyval[2]
		else if (keyval[1] == "PROTO")
			proto[i] = keyval[2]
		else if (keyval[1] == "SPT")
			spt[i] = keyval[2]
		else if (keyval[1] == "DPT")
			dpt[i] = keyval[2]
	}
	i++;
}
END {
	print "<table style=\"width:100%; text-align:center\">"
	print "<tr>" \
		"<th>Timestamp</th> <th>Protocol</th> <th>Source</th>" \
	      "<th>Destination</th> <th>Len.</th> <th>Flags</th></tr>"

	for (j=i-1; j > 0; j--) {
	#	print a[j]
	#	print tstamp[j], inp[j], oup[j], proto[j], src[j]":"spt[j], \
	#	dst[j]":"dpt[j], len[j], params[j];
		print "<tr>" \
		      "<td>"tstamp[j]"</td> <td>"proto[j]"</td>" \
		      "<td>"src[j]":"spt[j]"</td> <td>"dst[j]":"dpt[j]"</td>" \
		      "<td>"len[j]"</td> <td>"params[j]"</td></tr>"
	}
	print "</table>"
}
