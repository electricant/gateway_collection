package RecSQL;
use strict;
use warnings;
use IO::File;
use IO::String;
use Data::Dumper;

# Class to represent a single record
package RecSQL::Record;
sub new {
    my ($class, $data) = @_;
    return bless $data, $class;
}

sub get {
    my ($self, $field) = @_;
    if (ref $field eq 'ARRAY') {
        return { map { $_ => $self->{$_} } @$field };
    }
    return $self->{$field};
}

sub all_fields {
    my ($self) = @_;
    return [keys %$self];
}

sub as_hash {
    my ($self) = @_;
    return { %$self };
}

# Main RecSQL class
package RecSQL;

sub new {
    my ($class, $source, $is_string) = @_;
    my $self = {
        source => $source,
        is_string => $is_string || 0,
        filehandle => undef,
    };
    return bless $self, $class;
}

sub reset {
    my ($self) = @_;
    if ($self->{filehandle}) {
        if ($self->{is_string}) {
            $self->{filehandle}->setpos(0);
        } else {
            seek($self->{filehandle}, 0, 0);
        }
    }
}

sub _open {
    my ($self) = @_;
    if (!$self->{filehandle}) {
        if ($self->{is_string}) {
            $self->{filehandle} = IO::String->new($self->{source});
        } else {
            $self->{filehandle} = IO::File->new($self->{source}, "r") 
                or die "Cannot open $self->{source}: $!";
        }
    }
}

sub _close {
    my ($self) = @_;
    if ($self->{filehandle}) {
        $self->{filehandle}->close;
        $self->{filehandle} = undef;
    }
}

sub _read_next_record {
    my ($self) = @_;
    $self->_open();
    
    my $fh = $self->{filehandle};
    my $record = {};
    my $found_data = 0;

    while (my $line = <$fh>) {
        chomp $line;

        if ($line =~ /^(\w+)\s*:\s*(.*)$/) {
            my ($key, $value) = ($1, $2);
            $record->{$key} = $value;
            $found_data = 1;
        } elsif ($found_data) {
            last;
	  }
    }
    
    return %$record ? RecSQL::Record->new($record) : undef;
}

###
# NOTE: returns an array reference. Make sure to dereference it correctly
###
sub select {
    my ($self, $fields, $condition) = @_;
    $condition = sub { 1 } unless defined $condition;
    
    my @results;
    $self->_open();
    $self->reset();  # Reset to start of file/string before reading
    
    while (my $record = $self->_read_next_record()) {
        if ($condition->($record)) {
            if (!defined $fields || $fields eq '*') {
                push @results, $record->as_hash();
            } elsif (ref $fields eq 'ARRAY') {
                push @results, $record->get($fields);
            } else {
                push @results, $record->get($fields);
            }
        }
    }
    
    return \@results;
}

# Factory methods
sub from_file {
    my ($class, $filename) = @_;
    return $class->new($filename, 0);
}

sub from_string {
    my ($class, $string) = @_;
    return $class->new($string, 1);
}

1;
