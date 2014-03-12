use Bio::Chado::Schema;
use Data::Format::Pretty::Console qw(format_pretty);
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
		 ['query','Search string for searching through all tags in the database. Use "%" as a wildcard character, e.g., "%ISP%" will match anything with the characters ISP in it', { required => 1, validate => 'String'}],
	],
	'outputs' => [
	],
	'defaults' => [
		'appid'   => 'CHAPLIN_search',
		'appname' => 'Search for Features',
		'appdesc' => 'allows querying against the database by tag values',
	]
);


my $dsn = "dbi:Pg:dbname=" . $options->{database} . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Sequence::Feature')->search(
	{ name => { -like => $options->{query} } },
);

my @headers = ('id', 'organism id', 'organism common name', 'sequence length');
my @data = (
);
while(my $row = $results->next){
	push(@data, [$row->id, $row->organism->id, $row->organism->common_name, $row->seqlen]);
}

if($options->{verbose}){
	my @fp_data;
	foreach(@data){
		my %z;
		for(my$i=0;$i<scalar@{$_};$i++){
			$z{$headers[$i]} = ${$_}[$i];
		}
		push(@fp_data,\%z);
	}
	print format_pretty(\@fp_data);
}


my %crr_data = (
	'Sheet1' => {
		header => \@headers,
		data => \@data,
	}
);
$libCPT->classyReturnResults(
	name        => "search_results.csv",
	data        => \%crr_data,
	data_format => 'text/tabular',
	format_as   => 'CSV',
);
