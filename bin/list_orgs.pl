use Bio::Chado::Schema;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );


my $results = $chado->resultset('Organism::Organism')->search(
);

while(my $row = $results->next){
	print join("\t", $row->id, $row->genus, $row->species, $row->common_name),"\n";
		
}

