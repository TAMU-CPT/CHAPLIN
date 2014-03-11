use Bio::Chado::Schema;
use Data::Format::Pretty::Console qw(format_pretty);
use strict;
use warnings;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );


my $results = $chado->resultset('Organism::Organism')->search(
);

my @data = (
	['ID', 'Genus', 'Species', 'Common Name'],
);

while(my $row = $results->next){
	push(@data, [$row->id, $row->genus, $row->species, $row->common_name]);
}
print format_pretty(\@data);

