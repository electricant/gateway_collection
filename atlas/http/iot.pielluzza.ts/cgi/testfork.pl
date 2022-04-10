#!/bin/env perl
#
use v5.12;
use warnings;
use POSIX;

print "HTTP/1.0 200 OK\n";
print "Content-Type: text/plain; charset=utf-8\n";
print "Connection: Close\n\n";

my $sleep=15;

my $pid = fork();
if( $pid == 0 ) {
	# Inside here lives the child process
	
	# Close all standard filehandles to tell the server we are done
	for my $handle (*STDIN, *STDOUT, *STDERR) {
		open($handle, "+<", "/dev/null") || die "can't reopen $handle to /dev/null: $!";
	} #docstore.mik.ua/orelly/perl4/cook/ch17_18.htm
	
	# Create a new session for our code to run
	POSIX::setsid();

	sleep($sleep); # Do stuff, accessing the same data as the parent process

	exit 0;
}

print "Parent process is existing\n";
sleep(1);
exit 0;
