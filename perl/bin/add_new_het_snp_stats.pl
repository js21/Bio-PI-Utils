#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;


my @list_of_files = qw(15.stats.old 30.stats.old 48.stats.old 65.stats.old);


print Dumper(\@list_of_files);

for my $filename(@list_of_files) {

  my ($new_headers,$new_rows) = split_old_file($filename);
  write_new_file($filename,$new_headers,$new_rows);

}

sub split_old_file {

  my ($filename) = @_;
  my @headers_to_insert = ('"Heterozygous SNPs"', '"Genome Het SNPs %"', '"Total genome covered Het SNPs %"');
  my @values_to_insert = ("NA","NA","NA");
  my @lane_5477_6_3_values_to_insert = (387, 0.0176312927655662, 0.0246974876847605);

  open(my $fh, '<', $filename);
  my @lines = <$fh>;
  my @old_headers;
  my @new_headers;
  my %old_rows;
  my %new_rows;
  for (my $i = 0; $i < scalar @lines; $i++) {
    if ($i == 0) {
      @old_headers = split(/\t/, $lines[$i]);
      for (my $j = 0; $j < scalar @old_headers; $j++) {
	$old_headers[$j] =~ s/\n//;
	push(@new_headers, $old_headers[$j]);
	if ($old_headers[$j] eq '"Transposon %"') {
	  push(@new_headers, @headers_to_insert);
	}
      }
    }
    else {
      my @old_rows = split(/\t/, $lines[$i]);
      $old_rows{$i} = \@old_rows;
      for my $row(sort keys %old_rows) {
	my @new_row_items;
	for (my $j = 0; $j < scalar @{ $old_rows{$row} }; $j++) {
	  $old_rows{$row}->[$j] =~ s/\n//;
	  push(@new_row_items, $old_rows{$row}->[$j]);
	  if ($j == 17) {
	    if ('5477_6#3' ~~ @{$old_rows{$row}}) {
	      push(@new_row_items,@lane_5477_6_3_values_to_insert);
	    }
	    else {
	      push(@new_row_items,@values_to_insert);
	    }
	  }
	  $new_rows{$row} = \@new_row_items;
	}
      }
    }
  }
  close($fh);
  return(\@new_headers,\%new_rows);
}


sub write_new_file {

  my ($filename,$new_headers,$new_rows) = @_;
  my $new_filename = $filename . '.mod';
  $filename =~ s/\.old//;
  open(my $fh, '>', $new_filename);
  my $header_string;
  for my $header( @ { $new_headers } ) {
    $header_string .= "$header\t";
  }
  $header_string =~ s/\t$/\n/;

  my $string_of_rows;
  for my $row( sort keys %{ $new_rows } ) {
    for my $item( @{ $new_rows->{$row} } ) {
      $string_of_rows .= "$item\t";
    }
    $string_of_rows =~ s/\t$/\n/;
  }
  print $fh "$header_string";
  print $fh "$string_of_rows";
  close($fh);
  `mv $new_filename $filename`;
}

