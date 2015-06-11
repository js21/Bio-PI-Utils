#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Bio::SeqIO;

main();


sub main {

  my $fasta_filename = 'mock';
  GetOptions( "f|fasta_file=s" =>  \$fasta_filename);

  croak "$fasta_filename does not exist" unless( -e $fasta_filename );

  extract_base_counts_to_hash($fasta_filename);


}

sub extract_base_counts_to_hash {

  my ($fasta_filename) = @_;

  my $seqio_obj = Bio::SeqIO->new(-file => $fasta_filename, -format => "fasta" );

  while (my $seq_obj = $seqio_obj->next_seq){
    open( my $fh, '>', './' . $seq_obj->primary_id . '.coverageplot');
    open( my $fh_all, '>>', './all.coverageplot');
    open( my $fh_all_for_tabix, '>>', './all_for_tabix.coverageplot');

    my $line_label = $seq_obj->primary_id;
    use Data::Dumper;
    print Dumper($line_label);
    
    for (my $i = 0; $i < $seq_obj->length; $i++) {
      my $base_position = $i + 1;
      my $rand_sense = int(rand(10));
      my $rand_antisense = int(rand(10));

      print $fh ("$rand_sense\t$rand_antisense\n");
      print $fh_all ("$rand_sense\t$rand_antisense\n");
      print $fh_all_for_tabix ("$line_label\t$base_position\t$rand_sense\t$rand_antisense\n");

    }
    close($fh);

  }

}
