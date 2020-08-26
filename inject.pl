#!/usr/bin/perl
use strict;
use warnings;
use 5.028;
use Data::Dumper;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::CSV qw( csv );
use DBIx::Simple;
use Getopt::Long;

my $dir = '~/tmp/corona';
my $quiet       = 0;
my $search_etag = '*';
my $db_host = '';
my $db_name = 'corona';
my $db_user = $ENV{CORONA_DB_USER};
my $db_pass = $ENV{CORONA_DB_PASS};

GetOptions(
	"etag=s" => \$search_etag,    # etag to inject one specific file
	"dir=s"  => \$dir,            # zip-file location
	"quiet"  => \$quiet,          # flag
    'host=s' => \$db_host,
    'name=s' => \$db_name,
    'user=s' => \$db_user,
    'pass=s' => \$db_pass,
) or die("Error in command line arguments\n");

$db_host = ";host=$db_host" if $db_host;

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
	"DBI:Pg:database=$db_name".    # DBI source specification
    $db_host,
	$db_user,        # Username and password
	$db_pass,
	{ RaiseError => 1 }          # Additional options
);



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
