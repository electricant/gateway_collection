BEGIN { print "# Timestamp,temperature,humidity" }
{
	split($4, temp, ",");
	sub("}", "", $5); # Sub works in place
	date = strftime("%Y-%m-%d_%H:%M", $1);

	print date "," temp[1] "," $5;
}
