use Bio::Chado::Schema;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $results = $chado->resultset('Sequence::Featureprop')->search(
	{ value => { like => "%spanin%" } },
	{ join => ['cvterm', 'feature'] }
);

my @headers = ('Organism', 'Feature Name', 'Tag', 'Value');
print join("\t", @headers),"\n";
my @feature_ids;
while(my $row = $results->next){
	#push(@feature_ids, $row->feature_id);
	#printf("%s\t%s\t%s\t%s\n", $row->feature_id, $row->cvterm->name, $row->value, $row->feature->name);
	print join("\t", $row->feature->organism->common_name, $row->feature->name, $row->cvterm->name, $row->value),"\n";
}
