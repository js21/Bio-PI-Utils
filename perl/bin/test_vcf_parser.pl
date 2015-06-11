#!/usr/bin/env perl


use strict;
use warnings;
use Data::Dumper;
use Vcf;


my $variant_file = '/lustre/scratch108/pathogen/js21/hetero_exp/pileup/like_pipeline_var.raw.vcf';

my $vcf = Vcf->new(file=>$variant_file);

print Dumper($vcf);
my $header = $vcf->parse_header();


my $x = $vcf->next_data_hash();
my ($alleles,$seps,$is_phased,$is_empty) = $vcf->parse_haplotype($x,'FORMAT');
print "$alleles\n";

=head

while (my $x=$vcf->next_data_hash()) {
  for my $gt (keys %{$$x{gtypes}}) {
    my ($al1,$sep,$al2) = $vcf->parse_alleles($x,$gt);
    print "\t$: $al1$sep$al2\n";
  }
  print "\n";
}

=cut

