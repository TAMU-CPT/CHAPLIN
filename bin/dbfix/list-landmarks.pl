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
		'seqlen' => { '!=', undef }
	},
);

my @data;

my %hash;
while(my $row = $results->next){
	my $oid = sprintf('%s [%s]', $row->organism->common_name,$row->organism->id);
	if(! defined $hash{$oid}){
		$hash{$oid} = [];
	}
	push(@{$hash{$oid}}, $row->feature_id);
}

foreach(sort{scalar(@{$hash{$a}}) <=>  scalar(@{$hash{$b}})} keys(%hash)){
	print "Organism $_ has " . scalar(@{$hash{$_}}) . " child sequences\n";
}
