use Bio::Chado::Schema;
use strict;
use warnings;

# PODNAME: chaplin-find-orgs-without-tag.pl
use Data::Dumper;
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
		[ 'query_mode', 'How is the input query constructed? Is it a regular query with ? and * as wildcards, is it a SQL conformant regex query, is it a proper regex query?', { validate => "Option", options => { 'like' => 'Normal query with wildcards', 'similar' => 'Uses SQL regex', 'regex' => 'Proper Regex'}, default => 'like'}],
		[
			'query',
			'Tag Value to be queried in the database. Information about the feature will be printed if it exists in that organism, or a notice will be printed if it was not found. Use * for wildcard',
			{
				required => 1,
				validate => 'String'
			}
		],
	],
	'outputs' => [
		[
			'results',
			'Search Results',
			{
				validate       => 'File/Output',
				required       => 1,
				default        => 'orgs',
				data_format    => 'text/html',
				default_format => 'HTML'
			}
		],
	],
	'defaults' => [
		'appid'   => 'CHAPLIN_advanced_search',
		'appname' => 'Advanced Tag Search',
		'appdesc' => 'searches for organisms with and without a specified query string',
	]
);



my $dsn = "dbi:Pg:dbname=" . $options->{database} . ";host=cpt.tamu.edu;port=5432;sslmode=require";
my $user = "charm_admin";
my $password = "oNFkI0KyoGygRp8Zf7jOVIrR1VmsOWak";
my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

my $query = $options->{query};
if($options->{mode} eq 'like'){
	$query =~ s/\*/%/g;
}
my %preformatted_query;
if($options->{query_mode} eq 'like'){
	$preformatted_query{like} = $query;
}elsif($options->{query_mode} eq 'similar'){
	$preformatted_query{similar_to} = $query;
}elsif($options->{query_mode} eq 'regex'){
	$preformatted_query{'like'} = \"% AND value ~ $query";
	#$preformatted_query{'~'} = $query;
}else{
	die 'Bad mode specified';
}

print Dumper \%preformatted_query;

my $results = $chado->resultset('Organism::Organism')->search(undef, { 'order_by' => {'-asc', 'species', '-asc', 'genus', '-asc', 'common_name' } });

use CPT::Report;
use CPT::Report::HTML;
my $report = CPT::Report::HTML->new();
$report->title("Query");



my %cvterms_to_lookup;
my @haves;
my @havenots;

# Search through orgs
while(my $row = $results->next){
	#$report->h1(sprintf("<i>%s. %s</i> (%s)", substr($row->genus,0,1), $row->species, $row->common_name));
	my %org_results = (
		features => query_organism($row->id),
		genus =>  $row->genus,
		species =>  $row->species,
		common_name =>  $row->common_name,
	);

	if(scalar @{$org_results{features}} > 0){
		push(@haves, \%org_results);
	}else{
		push(@havenots, \%org_results);
	}
}

my %tn = (
	primary_tag => "Primary Tag",
	start       => "Start",
	end         => "End",
	strand      => "Strand",
	timelastmodified => "Last Modified",
);
my @tnkeys = qw/start end strand timelastmodified/;

my %cv = load_cvterms();
$report->h1("Organisms with matching features");
foreach my $organism(@haves){
	my %d = %{$organism};
	$report->h3(sprintf("%s %s", $d{genus},$d{species}));
	my @fp = @{$d{features}};
	foreach(@fp){
		$report->h4("Matching feature");
		my %fi = %{$_};

		$report->table_header('Key','Value');
		$report->table_row($tn{primary_tag}, $cv{$fi{primary_tag}});

		foreach(@tnkeys){
			$report->table_row($tn{$_}, $fi{$_});
		}
		foreach(@{$fi{featprops}}){
			my ($id,$val,$rank) = @{$_};
			$report->table_row('Tag: ' . $cv{$id}, $val);
		}
		$report->finalize_table();
	}



}
$report->h1("Organisms without matching features");
$report->list_start('bullet');
foreach my $organism(@havenots){
	my %d = %{$organism};
	$report->list_element(sprintf("%s %s", $d{genus}, $d{species}));
}
$report->list_end();






# Search within an org.
sub query_organism {
	my ($oid) = @_;
	my $features = $chado->resultset('Sequence::Featureprop')->search(
		{ 
			'feature.organism_id' => $oid,
			value => \%preformatted_query,
		},
		{ join => ['cvterm', 'feature'] , },
	);
	my $i = 0;
	my @hits;
	while(my $row = $features->next()){
		if($i == 0 && $options->{verbose}){
			print STDERR "Hit in $oid\n";
		}
		$i++;
		my $feature_ref = feature_info($row->feature_id());
		if(defined $feature_ref){
			push(@hits, $feature_ref);
		}
	}
	return \@hits;
}
sub feature_info {
	# Returns 1 feature.
	my ($fid) = @_;
	my $feature_info = $chado->resultset('Sequence::Feature')->search(
		{ 
			'feature_id' => $fid,
		},
		#{ join => ['featureloc_features'] , },
	)->first;
	
	my @featprops = $feature_info->featureprops;
	my $loc = $feature_info->featureloc_features->first;
	# Lazily evaluate
	foreach(@featprops){
		$cvterms_to_lookup{$_->type_id}++;
	}
	$cvterms_to_lookup{$feature_info->type_id}++;
	if(defined $loc){
		my %feature_info = (
			primary_tag => $feature_info->type_id,
			start       => $loc->fmin+ ($loc->strand == 1 ? 1:0),
			end         => $loc->fmax+ ($loc->strand == 1 ? 1:0),
			strand      => $loc->strand,
			featprops   => [map { [ $_->type_id, $_->value, $_->rank]} @featprops],
			timelastmodified => $feature_info->timelastmodified,
		);
		return \%feature_info;
	}
	return;
}
sub load_cvterms {
	# Lookup the cvterms
	my @cvterm_list = map { { cvterm_id => $_ } } keys(%cvterms_to_lookup);
	my $cvterms = $chado->resultset('Cv::Cvterm')->search(
		\@cvterm_list
	);
	my %cv;
	while(my $term = $cvterms->next){
		$cv{$term->cvterm_id} = $term->name;
	}
	return %cv;
}


use CPT::OutputFiles;
my $data_out = CPT::OutputFiles->new(
	name   => 'results',
	libCPT => $libCPT,
);
$data_out->CRR(data => $report->get_content);
