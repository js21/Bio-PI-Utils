#!/usr/bin/env perl

use strict;
use warnings;
use DBI;

my $database = 'pathogen_prok_track_test';
my $hostname = 'mcs11';
my $port = '3346';
my $user = 'pathpipe_ro';

my $study_id = 3387;

my $sql = <<"END_OF_SQL";
select la.`name`, s.`sample_id`, p.`study_id`, p.`ssid` from lane as la 
inner join library as li on (li.`library_id` = la.`library_id`)
inner join sample as s on (s.`sample_id` = li.`sample_id`)
inner join project as p on (p.`project_id` = s.`project_id`)
where p.`ssid` = $study_id
and p.`study_id` IS NOT NULL
group by la.`name`
order by la.`name`;
END_OF_SQL


my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

my $dbh = DBI->connect($dsn, $user);

my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
  print "Found a row: name = $ref->{'name'}, sample_id = $ref->{'sample_id'}, study_id = $ref->{'study_id'}, ssid = $ref->{'ssid'}\n";
}
$sth->finish();

# Disconnect from the database.
$dbh->disconnect();
