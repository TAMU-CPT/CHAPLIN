use Bio::Chado::Schema;
use strict;
use warnings;

my $dsn = "dbi:Pg:dbname=" . $ARGV[0] . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );


my $results = $chado->resultset('Sequence::Feature')->search(
	{
		#organism_id =>341, 
	}
	);

my %cv_terms;
while(my $row = $results->next){
	$cv_terms{$row->type_id}++;
}

my %results;
foreach my $k (keys(%cv_terms)){
	$results = $chado->resultset('Cv::Cvterm')->search({
		cvterm_id => $k
	});
	while(my $row = $results->next){
		$results{sprintf("%-40s", $row->name)} = $cv_terms{$k};
	}
}

foreach my $k (sort {$results{$a} <=> $results{$b}} (keys %results)){
	printf("%s %-10s\n", $k, $results{$k});
}

