#!/usr/bin/perl
use strict;
use warnings;
use 5.028;
use Data::Dumper;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::CSV qw( csv );
use DBIx::Simple;
use Getopt::Long;

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
	'DBI:Pg:database=corona',    # DBI source specification
	$ENV{CORONA_DB_USER},        # Username and password
	$ENV{CORONA_DB_PASS},
	{ RaiseError => 1 }          # Additional options
);

my $dir = '~/tmp/corona';

my $quiet       = 0;
my $search_etag = '*';

GetOptions(
	"etag=s" => \$search_etag,    # etag to inject one specific file
	"dir=s"  => \$dir,            # zip-file location
	"quiet"  => \$quiet,          # flag
) or die("Error in command line arguments\n");

my @etagged_zip_files;
my $search_pattern = '';
if ( $search_etag eq 'old' ) {

	# when downloading multiple files from wayback-machine,
	# they are stored as 'data (\d+).zip' by the browser.
	$search_pattern = "$dir/*(*).zip";
}
else {
	$search_pattern = "$dir/*.$search_etag.zip";
}

@etagged_zip_files = glob $search_pattern;

for my $file (@etagged_zip_files) {
	if ( $file =~ /\.([^.]+)\.zip/ || $file =~ /\((\d+)\)\.zip/ ) {
		my $etag = $1;
		my @seen = $db->select( 'districts', 'DISTINCT etag', { etag => $etag } )->hashes;

		#warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@seen], ['seen']);
		#warn "skipping $etag" if @seen;
		next if @seen;
		warn $file unless $quiet;

		# Read a Zip file
		my $zip = Archive::Zip->new();
		unless ( $zip->read($file) == AZ_OK ) {
			die 'read error';
		}
		my $csv = $zip->contents('Bezirke.csv');
		my $aoh = csv(
			in => \$csv,

			#headers => "auto",
			detect_bom => 1,
			sep_char   => ";",
		);    # as array of hash
		my $check_rowns = $etag =~ /^\d+$/;
		for my $row (@$aoh) {
			if ($check_rowns) {
				@seen = $db->select( 'districts', 'DISTINCT timestamp', 
					{ timestamp => $row->{timestamp}, gkz => $row->{gkz} } 
					)->hashes;
				if (@seen) {
					warn "skipping $row->{gkz} $row->{timestamp}";
					next;
				}
			}
			$row->{anzahl_inzidenz} =~ s/,/./;
			$db->insert( 'districts', { %$row, etag => $etag } );
		}
	}
}
