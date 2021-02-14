#!/usr/bin/perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;

use DBIx::Simple;
use Date::Parse;
use POSIX qw(strftime);
use File::Slurper qw(write_text);
use File::Touch;

my $tmp_marker = '/tmp/impfst_done_for_today';
my $file = '/var/www/impfst.at/index.html';

# Connecting to a MySQL database
my $db = DBIx::Simple->connect(
	'DBI:Pg:database=corona;host=127.0.0.1',    # DBI source specification
	$ENV{CORONA_DB_USER},                       # Username and password
	$ENV{CORONA_DB_PASS},
	{ RaiseError => 1 }                         # Additional options
);
my @fresh_data = $db->select( 'impfst_28d_done', 'teilgeimpfte_est_date', { BundeslandID => 10 } )->hashes;
if (@fresh_data) {
	exit if -e $tmp_marker;
	my $time = str2time( $fresh_data[0]->{teilgeimpfte_est_date} );

	#say strftime('%d.%m.%Y', localtime($time));
	my $done_date = strftime( '%d.%m.%Y',       localtime($time) );
	my $now_date  = strftime( '%d.%m.%Y %H:%M', localtime() );
	my $html      = <<XXX;
<html>
<head>
</head>
<body>
Based upon the data available from <a href="https://orf.at/">orf.at</a> all Austrians will recieve their first SARS Cov2 jab by this date:<br>
<h1>$done_date</h1>
This was calculated extrapolating the vaccination progress over the last 28 days.<br>
Last updated: $now_date (once a day unless something goes wrong)
This site is not affiliated with anyone and was only created to take my mind off the fact that a 'wird scho nix sein' person I recently met was tested positive the very next day. Source: <a href="https://github.com/qorron/corona_sepp">github</a><br>
Update: just got tested negative on day 3 after the incident. so: yay!<br><br>
Oh, and see what may happen if you <a href="http://impfst.net">impfst.net</a>.
</body>
</html>
XXX
	write_text( $file, $html );
	touch($tmp_marker);
}
else {
	unlink $tmp_marker if -e $tmp_marker;
	warn "update failed!";
}


