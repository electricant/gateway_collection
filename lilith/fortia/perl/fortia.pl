#!/usr/bin/perl
#
# Perl version of the fortia authenticator
#
use LWP::UserAgent;

# Constants:
my $ENET = -1;   # Returned in case of a network error
my $EAUTH = -2;  # Returned if the username or password are wrong
my $AUTH_OK = 1; # Already authenticated

# Global config variables
my $AUTH_TARGET = 'http://192.168.65.254:1000'; # URL to which POST data is sent
my $REF_INTERVAL_MIN = 15;
my $TEST_ADDRESS = 'http://www.example.com';
my $USER_AGENT = 'Lilith-Daemon';

# Authentication username and password are laced in a separate file for easier
# editing and modifying bu external programs
require 'user.pl';

##
# Main algorithm:
# Authenticate and keep refreshing periodically if still authenticated.
# Otherwhise retry authentication.

# Setup user agent object
my $ua = LWP::UserAgent->new;
$ua->agent($USER_AGENT);

my $status = doAuth();

if ($status == $ENET) {
	print "Network error!\n";
	exit $ENET;
} elsif ($status == $EAUTH) {
	print "Wrong user name or password for $USERNAME.\n";
	exit $EAUTH;
} elsif ($status == $AUTH_OK) { # $AUTH_OK was set to 1 because in perl a
# string is actually equal to 0. This is rather strange!
	print "Already authenticated.\n";
	exit 0;
}
# if we get here the authentication was succesful
my $toRefresh = $status;
print "Authentication succesful.\nRefreshing: $toRefresh\n";

while (true) {
	$status = doAuth();
	if ($status == $AUTH_OK) {
		if(refreshKeepalive($toRefresh) == $ENET) {
			print "Network error!\n";
			exit $ENET;
		}
	} elsif ($status == $ENET) {
		print "Network error!\n";
		exit $ENET;
	} else {
		$toRefresh = $status;
		print "Reauthenticated.\nRefreshing: $toRefresh\n";
	}
	sleep($REF_INTERVAL_MIN * 60);
}

# Authenticate against the firewall. Using the username and password provided.
# Returns:
#    $ENET          -> In case of a network error
#    $EAUTH         -> If the username or password are wrong
#    $AUTH_OK       -> If the user is already authenticated
#    URL to refresh -> If the authentication was succesful
sub doAuth {
	# First send a dummy request just to extract the 'magic'
	my $req = HTTP::Request->new(GET => $TEST_ADDRESS);
	my $resp = $ua->request($req);

	if (not $resp->is_success) {
		print "HTTP GET error code: ", $resp->code, "\n";
		print "HTTP GET error message: ", $resp->message, "\n";
		return $ENET;
	}

	my $magic = getMagic($resp->decoded_content);
	# if $magic is empty we are already authenticated. Just return.
	if (not $magic) {
		print $magic;
		return $AUTH_OK;
	}

	# Authenticate against $AUTH_TARGET with a POST request
	my $req = HTTP::Request->new(POST => $AUTH_TARGET);
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("username=$USERNAME&password=$PASSWORD&magic=$magic" .
		"&4Tredir=\\");
	my $resp = $ua->request($req);

	if (not $resp->is_success) {
	    print "HTTP POST error: ", $resp->status_line, "\n";
	    return $ENET;
	}

	# Extract the URL that has to be periodically refreshed
	my $refURL = getRefreshURL($resp->content);
	if (not $refURL) {
		return $EAUTH;
	} else {
		return $refURL;
	}
}

sub refreshKeepalive {
	# Send an HTTP request to refresh the keepalive page
	my $req = HTTP::Request->new(GET => $_[0]);
	my $resp = $ua->request($req);

	if (not $resp->is_success) {
		print "HTTP GET error code: ", $resp->code,"\n";
		print "HTTP GET error message: ", $resp->message, "\n";
		return $ENET;
	}
}

sub getMagic {
	foreach (split(/\n/, $_[0])) {
		$_ =~ /name="magic" value="([a-f0-9]+)"/ || next;
		return $1;
	}
}

sub getRefreshURL {
    foreach (split(/\n/, $_[0])) {
		$_ =~ /location\.href="(.*)"/ || next;
		return $1;
	}
}
