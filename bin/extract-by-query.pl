use Bio::Chado::Schema;
use Bio::Perl;
use strict;
use warnings;
use Data::Format::Pretty::Console qw(format_pretty);
use Bio::Tools::CodonTable;

my $codon_table = Bio::Tools::CodonTable->new(-id=>11);


my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Sequence::Featureprop')->search(
	{ value => { like => $ARGV[1] } },
	{ join => ['cvterm', 'feature'] }
);

my @data;
my @feature_ids;
my @fasta_sequences;
while(my $row = $results->next){
	# If it's a primary sequence, skip
	#if(defined $row->feature->seqlen && $row->feature->seqlen > 0){
		#print STDERR "Hit a primary sequence\t";
		#print STDERR $row->feature->feature_id;
		#print STDERR "\n";
		#next;
	#}

	# Grab the first referenced featureloc
	my @srcfeat = $row->feature->featureloc_features;
	#
	foreach(@srcfeat){
		my $srcfeat_id = $_->srcfeature_id;
		my $subquery = $chado->resultset('Sequence::Feature')->search(
			{ feature_id => $srcfeat_id }
		);
		my ($left, $right, $strand) = ($_->fmin, $_->fmax, $_->strand);
		while(my $subhit = $subquery->next){
			my $seq;
			if($strand == -1){
				$seq = substr($subhit->seq(),$left,($right-$left));
				$seq = revcom($seq)->seq;
			}else{
				$seq = substr($subhit->seq(),$left,($right-$left));
			}
			$seq = $codon_table->translate($seq);
			push(@data,
				{
					organsim      => $row->feature->organism->common_name,
					parent_length => $subhit->seqlen,
					tag           => $row->feature->uniquename,
					left          => $left,
					right         => $right,
					strand        => $strand,
					length        => length($seq),
					seq           => $seq,
					query_hit     => $row->value,
				}
			);

			my $tag =  $row->feature->organism->common_name . "_" . $ARGV[1];
			$tag =~ s/[^A-Za-z0-9_:.-]*//g;
			push(@fasta_sequences,
				sprintf(">%s [id=%s;length=%s;strand=%s;left=%s;right=%s]\n%s", $tag, $row->feature->uniquename,length($seq),$strand,$left,$right,$seq));
		}
	}
}

print format_pretty(\@data);
open(my $output,'>', 'out.fa');
print $output join("\n",@fasta_sequences);
close($output);
