#!/usr/bin/env perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;

use DateTime;
use Getopt::Long;
use File::Basename;
use Path::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::CSV qw( csv );
use DBIx::Simple;
use Encode;

my $url = 'https://info.gesundheitsministerium.at/data/data.zip';
my $now = DateTime->now->iso8601;

my $quiet       = 0;
my $dir         = '~/tmp/corona';
my $search_etag = '*';
my $db_host     = '';
my $db_name     = 'corona';
my $db_user     = $ENV{CORONA_DB_USER};
my $db_pass     = $ENV{CORONA_DB_PASS};
my $download    = 0;
my $inject      = 0;
my $use_PgPP    = '';

GetOptions(
    "dir=s"    => \$dir,            # zip-file location
    "etag=s"   => \$search_etag,    # etag to inject one specific file
    "quiet"    => \$quiet,          # flag
    'host=s'   => \$db_host,
    'name=s'   => \$db_name,
    'user=s'   => \$db_user,
    'pass=s'   => \$db_pass,
    'download' => \$download,
    'inject'   => \$inject,
    'use_pgpp' => \$use_PgPP,
) or die("Error in command line arguments\n");

$use_PgPP = 'PP' if $use_PgPP;


my $etag;
my $inject_ok = 0;
if ( $download ) {
    say "wget --server-response --spider $url" unless $quiet;
    my $head = `wget --server-response --spider $url 2>&1`;

    # ETag: "1f4e-5a7479899addf"
    if ( $head =~ /ETag: "([^"]+)"/ ) {
        $etag = $1;
        path($dir)->mkpath;
        my $search_pattern        = "$dir/*.$etag.zip";
        my @got_that_file_already = glob $search_pattern;
        if (@got_that_file_already) {
            say "file exists: " . join ' ', @got_that_file_already
                unless $quiet;
            exit;
        }
        my $filename    = "$dir/data_$now.$etag.zip";
        my $wget_output = `wget -nv $url -O $filename 2>&1`;
        if ($?) {
            die "download failed:\n\n$wget_output";
        }
        elsif ( !$quiet ) {
            say $wget_output;
        }
        $inject_ok = 1;
    }
    else {
        die "no ETag found in header:\n\n$head";
    }
}
else {
    $inject_ok = 1;
}

if ( $inject && $inject_ok ) {

    $db_host = ";host=$db_host" if $db_host;

    # Connecting to a MySQL database
    my $db = DBIx::Simple->connect(
        "DBI:Pg${use_PgPP}:database=$db_name" .    # DBI source specification
            $db_host,
        $db_user,                       # Username and password
        $db_pass,
        { RaiseError => 1 }             # Additional options
    );

    my @etagged_zip_files;
    my $search_pattern = '';
    $search_etag = $etag if $etag;
    if ( $search_etag eq 'old' ) {

        # when downloading multiple files from wayback-machine,
        # they are stored as 'data (\d+).zip' by the browser.
        $search_pattern = "$dir/*(*).zip";
    }
    elsif($search_etag eq 'all') {
        # use all the files. but still, 
        # files have to adhere to one of the two formats.
        $search_pattern = "$dir/*.zip";
    }else {
        $search_pattern = "$dir/*.$search_etag.zip";
    }

    @etagged_zip_files = glob $search_pattern;

    for my $file (@etagged_zip_files) {
        if ( $file =~ /\.([^.]+)\.zip/ || $file =~ /\((\d+)\)\.zip/ ) {
            my $file_etag = $1;
            my @seen =
                $db->select( 'districts', 'DISTINCT etag', { etag => $file_etag } )
                ->hashes;

            #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@seen], ['seen']);
            #warn "skipping $file_etag" if @seen;
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

            # only check for existing rows if we are in web-archive mode
            my $check_rows = $file_etag =~ /^\d+$/;
            for my $row (@$aoh) {
                if ($check_rows) {
                    @seen = $db->select(
                        'districts',
                        'DISTINCT timestamp',
                        {   timestamp => $row->{timestamp},
                            gkz       => $row->{gkz}
                        }
                    )->hashes;
                    if (@seen) {
                        warn "skipping $row->{gkz} $row->{timestamp}";
                        next;
                    }
                }
                $row->{anzahl_inzidenz} =~ s/,/./;
                eval {
                    $row->{bezirk} = encode( 'utf8', $row->{bezirk} )
                        if $use_PgPP;
                    $db->insert( 'districts', { %$row, etag => $file_etag } );
                };
                if ($@) {
                    warn $@;
                }
            }
        }
    }
}
