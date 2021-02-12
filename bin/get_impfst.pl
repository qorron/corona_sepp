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

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
    'DBI:Pg:database=corona',    # DBI source specification
    $ENV{CORONA_DB_USER},        # Username and password
    $ENV{CORONA_DB_PASS},
    { RaiseError => 1 }          # Additional options
);
my $aoh = csv(
	in => \$content,

	#headers => "auto",
	detect_bom => 1,
	sep_char   => ";",
	munge_column_names => "none",
);    # as array of hash

my @seen;
for my $row (@$aoh) {
	@seen =
		$db->select( 'impfst', 'DISTINCT Datum', { Datum => $row->{Datum}, BundeslandID => $row->{BundeslandID} } )->hashes;
	if (@seen) {
		# warn "skipping $row->{BundeslandID} $row->{Datum}";
		next;
	}
	say "inserting $row->{BundeslandID} $row->{Datum}";
	my $qt_row = {};
	for my $key (keys %$row) {
		$qt_row->{qq'"$key"'} = $row->{$key};
		say $key;
	}
	$db->insert( 'impfst', {%$qt_row} );
}
