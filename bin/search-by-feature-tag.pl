use Bio::Chado::Schema;
use strict;
use warnings;
use Data::Format::Pretty::Console qw(format_pretty);


# PODNAME: search-by-feature-tag.pl

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Sequence::Featureprop')->search(
	{ value => { like => "%spanin%" } },
	{ join => ['cvterm', 'feature'] }
);

my @data;
push(@data, ['Organism', 'Feature Name', 'Tag', 'Value']);
my @feature_ids;
while(my $row = $results->next){
	push(@data,[$row->feature->organism->common_name, $row->feature->name, $row->cvterm->name, $row->value]);
}

print format_pretty(\@data);
