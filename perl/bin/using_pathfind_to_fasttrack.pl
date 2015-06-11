#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use VRTrack::VRTrack;
use Path::Find;
use Path::Find::Lanes;
use Path::Find::Filter;
use Path::Find::LaneStatus;
use Path::Find::Sort;
use Path::Find::Exception;


main();


sub main {

  my @args = qw(-t study -i 2097);

  my $vrtrack = VRTrack::VRTrack->new({host => 'mcs11',
				       port => '3346',
				       database => 'pathogen_prok_track_test',
				       user => 'pathpipe_ro',
				       password => ''});
  print Dumper($vrtrack);
exit;
  my $type = 'lane';
  my $id = '11250_1#27';
  my $found = run($type,$id);


}

sub run {

  my ($type,$id) = @_;
  my $find = Path::Find->new();

  my @pathogen_databases = $find->pathogen_databases;
  my $lanes_found = 0;

  for my $database (@pathogen_databases) {
    my ( $pathtrack, $dbh, $root ) = $find->get_db_info($database);
    my $find_lanes = Path::Find::Lanes->new(
					    search_type => $type,
					    search_id => $id,
					    file_id_type => 'lane',
					    pathtrack => $pathtrack,
					    dbh => $dbh,
					    processed_flag => 0
					   );
    my @lanes = @{ $find_lanes->lanes };
    unless (@lanes) {
      $dbh->disconnect();
      next;
    }

    my $lane_filter;
    # filter lanes
    $lane_filter = Path::Find::Filter->new(
					   lanes => \@lanes,
					   root => $root,
					   pathtrack => $pathtrack,
					  );
    my @matching_lanes = $lane_filter->filter;
    unless (@matching_lanes) {
      $dbh->disconnect();
      next;
    }
    my $sorted_ml = Path::Find::Sort->new(lanes => \@matching_lanes)->sort_lanes;
    @matching_lanes = @{ $sorted_ml };

    for my $lane (@matching_lanes) {
      my $lane_status = Path::Find::LaneStatus->new(lane => $lane->{lane}, path => $lane->{path});
      print Dumper($lane_status);
    }
    $lanes_found = scalar @lanes;
    return 1 if $lanes_found;	# Stop looking if lanes found.
  }
  # No lanes found
  Path::Find::Exception::NoMatches->throw( error => "No lanes found for search of '$type' with '$id'\n")
      unless $lanes_found;

}
