use Bio::Chado::Schema;
use Data::Format::Pretty::Console qw(format_pretty);
use strict;
use warnings;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Organism::Organism')->search(
	{ common_name => { -like => $ARGV[1] } },
);

my @organism_ids;
while(my $row = $results->next){
	push(@organism_ids, $row->id);
	print "Found Organism: " , $row->common_name , "\n";
}

if(scalar @organism_ids > 1 || scalar @organism_ids == 0){
	die 'Please refine your search query so as to only select one organism';
}


my $features = $chado->resultset('Sequence::Feature')->search(
	{ organism_id => $organism_ids[0] },
	#{ join => ['featureloc_features', 'featureprops'] }
);



use Bio::SeqFeature::Generic;

# Must pre-create then hold features
my @features;
# store info for the eventual seqobj
my ($seq,$id);
# We need to resolve cvterms, however we cannot do this until after we've fetched features. It's a bit of a pain.
my %cvterms_to_lookup;
while(my $feat = $features->next){
	if($feat->seqlen){
		$seq = $feat->residues;
		$id = $feat->uniquename;
	}
	$cvterms_to_lookup{$feat->type_id}++;
	my @featprops = $feat->featureprops;
	my @featlocs = $feat->featureloc_features;
	foreach my $loc(@featlocs){
		foreach(@featprops){
			$cvterms_to_lookup{$_->type_id}++;
		}
		push(@features, {
			primary_tag => $feat->type_id,
			start       => $loc->fmin+ ($loc->strand == 1 ? 1:0),
			end         => $loc->fmax+ ($loc->strand == 1 ? 1:0),
			strand      => $loc->strand,
			featprops   => [map { [ $_->type_id, $_->value, $_->rank]} @featprops]
		});
	}
}


# Lookup the cvterms
use Data::Dumper;
my @cvterm_list = map { { cvterm_id => $_ } } keys(%cvterms_to_lookup);
my $cvterms = $chado->resultset('Cv::Cvterm')->search(
	\@cvterm_list
);
my %cv;
while(my $term = $cvterms->next){
	$cv{$term->cvterm_id} = $term->name;
}

# Load the qualifier mappings
open(my $qual_map,'<','qualifier_mapping');
my %qual_trans;
while(<$qual_map>){
	if($_ !~ /^#/){
		chomp $_;
		my ($a,$b) = split(/\s+/,$_);
		if($b){
			$qual_trans{$a} = $b;
		}
	}
}

# Create the sequence
use Bio::Seq;
my $seq_obj = Bio::Seq->new(
	-seq        => $seq,
	-display_id => $id,
);

# Create and add features
foreach(@features){
	my %f = %{$_};
	my %keys;
	# Translate the feature props into qualifiers
	foreach my $ref(@{$f{featprops}}){
		my ($id, $val0) = @{$ref};
		my $key = $cv{$id};
		# If there's a mapping we ought to use, use that
		if($qual_trans{$key}){
			$key = $qual_trans{$key};
		}
		unless($keys{$key}){
			$keys{$key} = [];
		}
		push($keys{$key},$val0);
	}
	# Create our new feature
	my $new_feat = new Bio::SeqFeature::Generic(
		-start       => $f{start},
		-end         => $f{end},
		-strand      => $f{strand},
		-primary_tag => $cv{$f{primary_tag}},
		-tag         => \%keys,
	);
	$seq_obj->add_SeqFeature($new_feat)
}

open(my $outfile,'>', $ARGV[1].'.gbk');
use Bio::SeqIO;
my $outseq = Bio::SeqIO->new(
	-fh => $outfile,
	-format => 'Genbank',
);
$outseq->write_seq($seq_obj);
