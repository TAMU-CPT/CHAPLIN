use Bio::Chado::Schema;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Sequence::Feature')->search(
		name => { -like => $ARGV[1] },
);

while(my $row = $results->next){
	printf("%s: %s\t%s\t%s\n", $row->id, $row->organism->id, $row->organism->common_name, $row->seqlen);
}
