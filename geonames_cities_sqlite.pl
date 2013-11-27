#!/usr/bin/perl -w

########################################################################
# Put Geonames.org data in a SQLite schema, especially for
# full-text search (see complete.php for Twitter typeahead.js usage)
#
# Copyright (c) 2013, Michael J. Radwin
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################

use strict;
use DBI;
use Carp;

die "usage: $0 geonames.sqlite3 countryInfo.txt cities15000.txt admin1CodesASCII.txt\n" unless @ARGV == 4;

my $file = shift;
my $in_country = shift;
my $in_cities = shift;
my $in_admin1 = shift;

my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "",
		       { RaiseError => 1, AutoCommit => 0 })
    or die $DBI::errstr;

do_sql($dbh, qq{DROP TABLE IF EXISTS geoname});

do_sql($dbh, qq{CREATE TABLE geoname ( 
    geonameid int PRIMARY KEY, 
    name nvarchar(200), 
    asciiname nvarchar(200), 
    alternatenames nvarchar(4000), 
    latitude decimal(18,15), 
    longitude decimal(18,15), 
    fclass nchar(1), 
    fcode nvarchar(10), 
    country nvarchar(2), 
    cc2 nvarchar(60), 
    admin1 nvarchar(20), 
    admin2 nvarchar(80), 
    admin3 nvarchar(20), 
    admin4 nvarchar(20), 
    population int, 
    elevation int, 
    gtopo30 int, 
    timezone nvarchar(40), 
    moddate date);});

do_sql($dbh, qq{DROP TABLE IF EXISTS admin1});

do_sql($dbh, qq{CREATE TABLE admin1 (
    key TEXT PRIMARY KEY,
    name nvarchar(200) NOT NULL,
    asciiname nvarchar(200) NOT NULL,
    geonameid int NOT NULL
    );});

do_sql($dbh, qq{DROP TABLE IF EXISTS country});

do_sql($dbh, qq{CREATE TABLE country (
  ISO TEXT PRIMARY KEY,
  ISO3 TEXT NOT NULL,
  IsoNumeric TEXT NOT NULL,
  fips TEXT NOT NULL,
  Country TEXT NOT NULL,
  Capital TEXT NOT NULL,
  Area INT NOT NULL,
  Population INT NOT NULL,
  Continent TEXT NOT NULL,
  tld TEXT NOT NULL,
  CurrencyCode TEXT NOT NULL,
  CurrencyName TEXT NOT NULL,
  Phone TEXT NOT NULL,
  PostalCodeFormat TEXT,
  PostalCodeRegex TEXT,
  Languages TEXT NOT NULL,
  geonameid INT NOT NULL,
  neighbours TEXT NOT NULL,
  EquivalentFipsCode TEXT NOT NULL
);});

do_file($dbh,$in_country,"country",19);
do_file($dbh,$in_cities,"geoname",19);
do_file($dbh,$in_admin1,"admin1",4);

do_sql($dbh, qq{DROP TABLE IF EXISTS geoname_fulltext});

do_sql($dbh, qq{CREATE VIRTUAL TABLE geoname_fulltext
USING fts3(geonameid int, longname text,
asciiname text, admin1 text, country text,
population int, latitude real, longitude real, timezone text
);
});

do_sql($dbh, qq{INSERT INTO geoname_fulltext
SELECT g.geonameid, g.asciiname||', '||a.asciiname||', '||c.Country,
g.asciiname, a.asciiname, c.Country,
g.population, g.latitude, g.longitude, g.timezone
FROM geoname g, admin1 a, country c
WHERE g.country = c.ISO
AND g.country||'.'||g.admin1 = a.key
});

$dbh->commit;
$dbh->disconnect();
undef $dbh;

exit(0);

sub do_sql {
    my($dbh,$sql) = @_;

    print STDERR $sql, "\n";
    $dbh->do($sql);
    $dbh->commit;
}

sub do_file {
    my($dbh,$infile,$table_name,$expected_fields) = @_;

    my $sql = "INSERT INTO $table_name VALUES (?";
    for (my $i = 0; $i < $expected_fields - 1; $i++) {
	$sql .= ",?";
    }
    $sql .= ")";
    print STDERR $sql, "\n";
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;

    my $fh;
    open($fh, "<:encoding(UTF-8)", $infile)
	or die "cannot open < $infile: $!";

    my $i = 0;
    while(<$fh>) {
	chomp;
	next if /^#/;
	my @a = split(/\t/, $_, -1);
	my $actual = scalar(@a);
	if ($actual != $expected_fields) {
	    carp "$infile:$.: got $actual fields (expected $expected_fields)\n";
	    next;
	}
	my $rv = $sth->execute(@a) or die $dbh->errstr;
	if (0 == $i++ % 1000) {
	    $dbh->commit;
	}
    }
    close($fh);
    $sth->finish;
    undef $sth;
    $dbh->commit;
}
