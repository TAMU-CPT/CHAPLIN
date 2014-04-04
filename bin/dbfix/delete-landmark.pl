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
			'feature_id',
			'Feature ID #',
			{
				required => 1,
				validate => 'String',
				multiple => 1,
			}
		],
	],
	'outputs' => [
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


foreach my $feature_id ( @{$options->{feature_id}}){
	my $results = $chado->resultset('Sequence::Feature')->search(
		{
			'feature_id' => $feature_id,
			'seqlen' => { '!=', undef }
		},
	);
	$results->delete;
}
