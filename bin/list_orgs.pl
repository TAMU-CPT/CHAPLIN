use Bio::Chado::Schema;
#use Data::Format::Pretty::Console qw(format_pretty);
use strict;
use warnings;


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


my $results = $chado->resultset('Organism::Organism')->search();

my @data;

while(my $row = $results->next){
	push(@data, [$row->id, $row->genus, $row->species, $row->common_name]);
}

my %crr_data = (
	'Sheet1' => {
		header => ['ID', 'Genus', 'Species', 'Common Name'],
		data => \@data,
	}
);
$libCPT->classyReturnResults(
	name        => "organism_list.csv",
	data        => \%crr_data,
	data_format => 'text/tabular',
	format_as   => 'CSV',
);

