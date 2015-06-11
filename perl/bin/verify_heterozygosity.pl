#!/usr/bin/env perl


use strict;
use warnings;
use Bio::SeqIO;

main();

sub main {

  my $variant_file = '/lustre/scratch108/pathogen/js21/hetero_exp/pileup/like_pipeline_var.raw.vcf';
  my $ref = '/lustre/scratch108/pathogen/pathpipe/refs/Staphylococcus/aureus_subsp_aureus_EMRSA15/Staphylococcus_aureus_subsp_aureus_EMRSA15_v1.fa';
  #my $genome_length = get_genome_length($ref);
  my ($genome_length,$het_based_on_af1_only,$het_based_on_fq_only,$het_based_on_af1_and_fq,$het_based_on_af1_or_fq,$het_based_on_ploidy) = cycle_through_vcf_file($variant_file);
  my $ploidy_percentage = ($het_based_on_ploidy * 100)/$genome_length;
  my $af1_only_percentage = ($het_based_on_af1_only * 100)/$genome_length;
  my $fq_only_percentage = ($het_based_on_fq_only * 100)/$genome_length;
  my $af1_or_fq_percentage = ($het_based_on_af1_or_fq * 100)/$genome_length;
  print"INDEX\tHET_SNPS\t%\n";
  print"PLOIDY\t$het_based_on_ploidy\t$ploidy_percentage\n";
  print"AF1\t$het_based_on_af1_only\t$af1_only_percentage\n";
  print"FQ\t$het_based_on_fq_only\t$fq_only_percentage\n";
  print"AF1\|FQ\t$het_based_on_af1_or_fq\t$af1_or_fq_percentage\n";

}

sub get_genome_length {

  my ($ref) = @_;
  my $seqio_object = Bio::SeqIO->new(-file => $ref);
  my $genome_length = 0;
  while( my $seq_object = $seqio_object->next_seq ) {
    if ( $seq_object->id =~ m/^chr/ ) {
      $genome_length += $seq_object->length;
    }
  }
  print "LENGTH: $genome_length\n";
  return($genome_length);
}

sub cycle_through_vcf_file {

  my ($variant_file) = @_;

  open(my $vcf_fh, '<', $variant_file);

  my $genome_length;
  my $het_based_on_af1_only = 0;
  my $het_based_on_fq_only = 0;
  my $het_based_on_af1_and_fq = 0;
  my $het_based_on_af1_or_fq = 0;
  my $het_based_on_ploidy = 0;
  my @dp_values;

  while( my $row = <$vcf_fh> ) {
    if ($row =~ m/^\#/) {
      if ($row =~ m/contig\=\<ID\=chr/) {
	$row =~ s/.*contig\=\<ID\=chr.*,length\=(\d+).*/$1/;
	$genome_length = $row;
      }
      next;
    }
    else {
      if ($row =~ m/^chr/) {
	my ($af1_value,$fq_value,$dp_value,$ploidy,$values) = get_het_indexes($row);
	push(@dp_values,$dp_value);
	$het_based_on_ploidy++ if ($ploidy eq '1/0' || $ploidy eq '0/1');
	$het_based_on_af1_only++ if ($af1_value == 1);
	if ($fq_value =~ m/^[0-9]/ ) {
	  $het_based_on_fq_only++;
	}
	if ($fq_value =~ m/^[0-9]/ && $af1_value == 1) {
	  $het_based_on_af1_and_fq++;
	}
	if ($fq_value =~ m/^[0-9]/ || $af1_value == 1) {
	  $het_based_on_af1_or_fq++;
	}
      }
      else {
	next;
      }
    }
  }

  print("DP_VALUES: ", scalar @dp_values, "\n");

  close($vcf_fh);

  return($genome_length,$het_based_on_af1_only,$het_based_on_fq_only,$het_based_on_af1_and_fq,$het_based_on_af1_or_fq,$het_based_on_ploidy);
}


sub get_het_indexes {

  my ($row) = @_;
  chomp($row);
  my @values = split(/\t/, $row);
  my $dp_value = $values[0];
  $dp_value =~ s/.*DP\=([0-9]+).*/$1/;
  my $fq_value = $values[7];
  $fq_value =~ s/.*FQ\=([\-0-9]+).*/$1/;
  my $af1_value = $values[7];
  $af1_value =~ s/.*AF1\=([\-0-9]+).*/$1/;
  my $ploidy = $values[9];
  $ploidy =~ s/(\d\/\d).*/$1/;


  my ($strand_bias,$baseQ_bias,$mapQ_bias,$tail_bias) = (0.001,0.001,0.001,0.001);

  my $pv4_values = $values[7];
  $pv4_values =~ s/.*;PV4\=([0-9\.]+,[0-9\.]+,[0-9\.]+,[0-9\.]+).*/$1/;
  if ($pv4_values =~ m/^\d/ ) {
    ($strand_bias,$baseQ_bias,$mapQ_bias,$tail_bias) = split(/,/,$pv4_values);
    print "$pv4_values\n";
    print "$strand_bias\t$baseQ_bias\t$mapQ_bias\t$tail_bias\n";
  }

  return($af1_value,$fq_value,$dp_value,$ploidy,\@values);
}
