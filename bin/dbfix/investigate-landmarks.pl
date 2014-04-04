use Bio::Chado::Schema;
#use Data::Format::Pretty::Console qw(format_pretty);
use strict;
use warnings;

# PODNAME: list_orgs.pl

use CPT;
my $libCPT = CPT->new();
my $options = $libCPT->getOptions(
	'options' => [
		[
			'database',
			'Database Name',
			{
				required => 1,
				validate => 'String'
			}
		],
		[
			'organism_id',
			'Organism ID #',
			{
				required => 1,
				validate => 'String'
			}
		],
	],
	'outputs' => [
		[
			'results',
			'Organism Listing',
			{
				validate       => 'File/Output',
				required       => 1,
				default        => 'orgs.csv',
				data_format    => 'text/tabular',
				default_format => 'CSV'
			}
		],
	],
	'defaults' => [
		'appid'   => 'CHAPLIN_list_organisms',
		'appname' => 'List Organisms',
		'appdesc' => 'lists organisms in a chado database',
	]
);



my $dsn = "dbi:Pg:dbname=" . $options->{database} . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );


my $results = $chado->resultset('Sequence::Feature')->search(
	{
		'organism_id' => $options->{organism_id},
		'seqlen' => { '!=', undef }
	},
);

my @data;
my %hash;
while(my $row = $results->next){
	printf "[%s]:
	Length:%s, Name%s, Type:%s
",$row->feature_id, $row->seqlen, $row->name, $row->type_id;
	my $related = $chado->resultset('Sequence::Feature')->search(
		{
			'seqlen' => { '=', undef },
			'featureloc_features.srcfeature_id' => $options->{$row->feature_id}
		},
		{
			join => ['featureloc_features']
		}
	);
	my ($num_features, $num_annotations) = (0,0);

	my $text;
	while(my $subrow = $related->next){
		$num_features++;
		$text .= $subrow->name.$subrow->type_id;
		my $fps = $subrow->featureprops->search();
		while(my $featureprop = $fps->next){
			$num_annotations++;
			$text .= $featureprop->value;
		}
		
		my $fls = $subrow->featureloc_features->search();
		while(my $featureloc = $fls->next){
			$text .= $featureloc->fmin . $featureloc->fmax . $featureloc->strand;
		}
	}
	use Digest::MD5 qw(md5_base64);
	my $digest = md5_base64($text);
	printf "\tHash of feature annotations: %s, Number of Features %s, Number of Annotations %s\n\n", $digest, $num_features, $num_annotations;
}
