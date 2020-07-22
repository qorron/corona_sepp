#!/usr/bin/perl
use strict;
use warnings;
use 5.028;
use Data::Dumper;

use DateTime;
use Getopt::Long;
use File::Basename;

my $url        = 'https://info.gesundheitsministerium.at/data/data.zip';
my $now        = DateTime->now->iso8601;

my $quiet      = 0;
my $dir        = '~/tmp/corona';
my $inject_dir = dirname(__FILE__);

GetOptions(
	"dir=s"        => \$dir,           # zip-file location
	"inject_dir=s" => \$inject_dir,    # location of inject.pl
	"quiet"        => \$quiet,         # flag
) or die("Error in command line arguments\n");
my $head = `HEAD $url`;

# ETag: "1f4e-5a7479899addf"
if ( $head =~ /ETag: "([^"]+)"/ ) {
	my $etag     = $1;
	my $search_pattern = "$dir/*.$etag.zip";
	my @got_that_file_already = glob $search_pattern;
	exit if @got_that_file_already;
	my $filename = "$dir/data_$now.$etag.zip";
	my $wget_output = `wget -nv $url -O $filename 2>&1`;
	if ($?) {
		die "download failed:\n\n$wget_output";
	}
	print `$inject_dir/inject.pl --etag "$etag" 2>&1`;
}
else {
	die "no ETag found in header:\n\n$head";
}


