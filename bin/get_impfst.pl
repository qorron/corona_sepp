#!/usr/bin/perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;
use LWP::Simple;
use DBIx::Simple;
use Text::CSV qw( csv );
use Encode;


my $url = 'https://pipe.orf.at/corona-dashboard/data/timeline-eimpfpass.csv?origin=orf.at';

my $content = encode('utf8',get($url));
$content =~ s/1;Gruppe<24_M_1;Gruppe<24_W_1;Gruppe<24_D_1/1;Gruppe<24_M_2;Gruppe<24_W_2;Gruppe<24_D_2/; # fix faulty headers
$content =~ s/ö/oe/; # avoid non-ascii
$content =~ s/[<>-]/_/g; # not screw up sql

my $host = '';
$host = ';host=127.0.0.1' if $ENV{CORONA_DB_USER} && $ENV{CORONA_DB_PASS};

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
    'DBI:Pg:database=corona'.$host,    # DBI source specification
    $ENV{CORONA_DB_USER},        # Username and password
    $ENV{CORONA_DB_PASS},
    { RaiseError => 1 }          # Additional options
);
my $aoh = csv(
	in => \$content,

	#headers => "auto",
	detect_bom => 1,
	sep_char   => ";",
#	munge_column_names => "none",
);    # as array of hash

my @seen;
warn "got no rows" unless @$aoh;
for my $row (@$aoh) {
	@seen =
		$db->select( 'impfst', 'DISTINCT Datum', { Datum => $row->{datum}, BundeslandID => $row->{bundeslandid} } )->hashes;
	if (@seen) {
		# warn "skipping $row->{BundeslandID} $row->{Datum}";
		next;
	}
	say "inserting $row->{bundeslandid} $row->{datum}";
	my $qt_row = {};
	for my $key (keys %$row) {
		$qt_row->{qq'"$key"'} = $row->{$key};
		delete $row->{$key} if $row->{$key} eq ''; # integer
	}
	#warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$row], ['row']);
	$db->insert( 'impfst', {%$row} );
}
