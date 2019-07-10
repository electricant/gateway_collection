#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use CGI qw();
use Switch;
# Output as utf-8
use utf8;
binmode(STDOUT, ":utf8");

#
# GLOBAL VARIABLES
#
our $SQUID_UNLOCKED_DOMAINS_FILE = "/etc/squid/unlock_domains.conf";
our $TMP_UNLOCKED_FILE = "/srv/http/cgi/unlock_domains.conf";
our $FORTIA_USER_FILE = "/root/ONAOSI/user.pl";
our $TMP_FORTIA_USER_FILE = "/srv/http/cgi/fortia_user.conf";

#
# MAIN
#
my $c = CGI->new;
$c->charset('utf-8');

if (!defined($c->param('action'))) {
	print "No action specified!";
} else {
	my $action = $c->param('action');
	
	switch ($action) {
		case 'dhcp_clients' { print_clients() }
		case 'get_unlocked' { print_unlocked_domains() }
		case 'mkdom'        { add_domain(scalar $c->param('domain')); }
		case 'rmdom'        { del_domain(scalar $c->param('id')); }
		case 'get_username' { get_fortia_user() }
		case 'chgauth'      { set_fortia_user() }
		else {
		    print $c->header(-type    => 'text/plain',
                             -charset => 'utf-8');
			print "Invalid action: $action" }
	}
}

# Subroutine to parse and print dhcp clients as a table
sub print_clients {
	my $leasefile = '/var/lib/misc/dnsmasq.leases';
	open(my $fh, '<:encoding(UTF-8)', $leasefile)
  		or die "Could not open file '$leasefile' $!";

	print $c->header(-type    => 'text/plain',
    	             -charset => 'utf-8');
	
	print '<table class="dhcptable"><thead><tr>' .
		'<th>IP</th><th>Hostname</th><th>MAC Address</th><th>Expire Date</th>' .
		'</tr></thead><tbody>';

	while (my $row = <$fh>) {
  		chomp $row;
  		my @values = split(' ', $row);
		
		my $expires = scalar(localtime($values[0]));
		my $mac = $values[1];
		my $ip = $values[2];
		my $hostname = $values[3];

		print '<tr><th>'.$ip.'</th><th>'.$hostname.'</th><th>'.$mac.
			'</th><th>'.$expires.'</th></tr>';
	}
	print '</tbody></table>';
}

# Print unlocked domains as a fancy table with input support
sub print_unlocked_domains {
	my @domains = read_domains();

	print $c->header(-type    => 'text/plain',
	                 -charset => 'utf-8');
	
	my $index = 0;
	foreach my $domain (@domains) {
		print '<tr><td><form action="/cgi/serverapi.pl" method="post">';
        print '<input type="text" name="domain" value="'.$domain.'" readonly>';
        print '<input type="hidden" name="id" value="'.$index.'">';
        print '<input type="hidden" name="action" value="rmdom">';
        print '<button type="submit"><i class="fa fa-times"></i>' . 
			'Elimina</button></form></td></tr>';
		$index++;
	}	
    print '<tr><td><form action="/cgi/serverapi.pl" method="post">';
    print '<input type="text" name="domain" placeholder="nuovosito.com">';
    print '<input type="hidden" name="action" value="mkdom">';
    print '<button type="submit"><i class="fa fa-plus"></i>' . 
            'Aggiungi</button></form></td></tr>';
}
# Read squid's configuration file and extract unlocked domains without the
# leading dot
sub read_domains {
	open(my $fh, '<:encoding(UTF-8)', $SQUID_UNLOCKED_DOMAINS_FILE)
		or die "Could not open unlocked domains file $!";
	
	my @domains; # Domains read from file will be put here
	
	while (my $row = <$fh>) {
  		chomp $row;
        my @values = split(' ', $row);
  		push(@domains, substr($values[3], 1));
	}

	return @domains;
}
# Create a valid config file for squid from a list of domains. Copy it to
# squid's config directory and reload its config file
# NOTE: this subroutine adds a leading dot to the domain name!
sub save_domains {
    open(my $fh, '>:encoding(UTF-8)', $TMP_UNLOCKED_FILE)
        or die "Could not write a new unlocked domains file $!";

	foreach my $domain (@_) {
		print $fh "acl UNLOCK dstdomain .$domain\n";
	}
	close $fh;
    # Need superuser privileges to overwrite the file & reload
    system("sudo cp $TMP_UNLOCKED_FILE $SQUID_UNLOCKED_DOMAINS_FILE");
	system("sudo squid -k reconfigure");
}
# Add an unlocked domain to the end of squid's configuration file
# No dot shall be placed before the domain name. The routine will do it for you
sub add_domain {
	my $domain = $_[0]; # extract the first argument

	if (length $domain == 0) { 
		print $c->redirect('http://192.168.6.1/options/index.html?EEMP');
	} elsif ($domain !~ /.+\...+/) {
		print $c->redirect('http://192.168.6.1/options/index.html?ENOV');
	} else {
		my @domains = read_domains();

		push(@domains, $domain);
		save_domains(@domains);
	}
	# Done just redirect to reload the page
	print $c->redirect('http://192.168.6.1/options/index.html');		
}
# Delete an unlocked domain from the list. The index is used to delete a domain
# and represents the line into the config file to be erased
sub del_domain {
	my $index = $_[0];
	my @domains = read_domains();

	if ($index < 0 or $index >= scalar(@domains)) {
		print $c->redirect('http://192.168.6.1/options/index.html?EIDX');
	} else {
		splice(@domains, $index, 1);
		save_domains(@domains);
	}
	# Done. Redirect
	print $c->redirect('http://192.168.6.1/options/index.html');	
}

# Get username from fortia config file
sub get_fortia_user {
    print $c->header(-type    => 'text/plain',
                     -charset => 'utf-8');

	open(my $fh, '<:encoding(UTF-8)', $FORTIA_USER_FILE)
        or die "Could not open fortia user config file $!";

    while (my $row = <$fh>) {
        chomp $row;
		$row =~ /our\h*\$USERNAME\h*=\h*['"]([a-z0-9]+)['"]/ || next;
		print $1;
    }
}

# Set username for fortia
sub set_fortia_user {
	my $username = $c->param('user');
	my $password = $c->param('pass');

	# Create new config file. Overwrite the old one and restart fortia
	open(my $fh, '>:encoding(UTF-8)', $TMP_FORTIA_USER_FILE)
        or die "Could not write a new fortia user file $!";

    print $fh "our \$USERNAME = '$username';\n";
    print $fh "our \$PASSWORD = '$password';\n";
	close $fh;
	
	# Need superuser privileges to overwrite the file & reload
    system("sudo cp $TMP_FORTIA_USER_FILE $FORTIA_USER_FILE");
    system("sudo systemctl restart wifi_connect");

	# Done. Redirect
	print $c->redirect('http://192.168.6.1/options/fortia.html');
}
