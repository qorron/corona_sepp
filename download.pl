#!/usr/bin/perl
use strict;
use warnings;
use 5.028;
use Data::Dumper;

use DateTime;
use Getopt::Long;
use File::Basename;
use Path::Tiny;

my $url        = 'https://info.gesundheitsministerium.at/data/data.zip';
my $now        = DateTime->now->iso8601;

my $quiet      = 0;
my $dir        = '~/tmp/corona';
my $inject_dir = dirname(__FILE__);
my $db_host = '';
my $db_name = 'corona';
my $db_user = $ENV{CORONA_DB_USER};
my $db_pass = $ENV{CORONA_DB_PASS};

GetOptions(
	"dir=s"        => \$dir,           # zip-file location
	"inject_dir=s" => \$inject_dir,    # location of inject.pl
	"quiet"        => \$quiet,         # flag
    'host=s' => \$db_host,
    'name=s' => \$db_name,
    'user=s' => \$db_user,
    'pass=s' => \$db_pass,
) or die("Error in command line arguments\n");
say "wget --server-response --spider $url" unless $quiet;
my $head = `wget --server-response --spider $url 2>&1`;


# ETag: "1f4e-5a7479899addf"
if ( $head =~ /ETag: "([^"]+)"/ ) {
	my $etag     = $1;
    path($dir)->mkpath;
	my $search_pattern = "$dir/*.$etag.zip";
	my @got_that_file_already = glob $search_pattern;
	if (@got_that_file_already) {
        say "file exists: ".join ' ', @got_that_file_already unless $quiet;
        exit;
    }
	my $filename = "$dir/data_$now.$etag.zip";
	my $wget_output = `wget -nv $url -O $filename 2>&1`;
	if ($?) {
		die "download failed:\n\n$wget_output";
	} elsif(!$quiet) {
        say $wget_output;
    }
	print `$inject_dir/inject.pl --etag "$etag" 2>&1`;
}
else {
	die "no ETag found in header:\n\n$head";
}


