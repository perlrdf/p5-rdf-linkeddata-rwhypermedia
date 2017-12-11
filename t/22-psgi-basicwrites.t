#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::RDF;
use RDF::Trine qw[iri literal blank variable statement];
use Test::WWW::Mechanize::PSGI;
use Module::Load::Conditional qw[check_install];
use RDF::Trine::Namespace qw(rdf);




$ENV{'RDF_LINKEDDATA_CONFIG_LOCAL_SUFFIX'} = 'acl';

my $tester = do $ENV{'ROBINHOME'}."/dev/RDF-LinkedData/script/linked_data.psgi";

BAIL_OUT("The application is not running") unless ($tester);

use Log::Any::Adapter;

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};


my $exprefix = 'http://example.org/hypermedia#';

my $parser = RDF::Trine::Parser->new( 'turtle' );

my $rxparser = RDF::Trine::Parser->new( 'rdfxml' );
my $base_uri = 'http://localhost/';


subtest 'Write operations without authentication' => sub {
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->post("/bar/baz/bing/data", { 'Content-Type' => 'text/turtle', 
													 Content => "<$base_uri/bar/baz/bing> <http://example.org/error> \"No merged triple\"\@en" });
	 is($mech->status, 401, "Posting returns 401");
  }
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->put("/bar/baz/bing/data", { 'Content-Type' => 'text/turtle',
													Content => "<$base_uri/bar/baz/bing> <http://example.org/error> \"No merged triple\"\@en" });
	 is($mech->status, 401, "Putting returns 401");
  }
};

my $prevcount = 0;
subtest 'Check before we write' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $model = check_content($mech);
  $prevcount = $model->size;
};


subtest 'Merge operations with authentication' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');

  $mech->post("/bar/baz/bing/data", { 'Content-Type' => 'text/turtle', 
												  Content => "<$base_uri/bar/baz/bing> <http://example.org/success> \"Merged triple\"\@en" });
  is($mech->status, 204, "Posting returns 204");

  my $model = check_content($mech);
  is($model->size, $prevcount+1, 'Got another triple now');
  has_predicate('http://example.org/success', $model, 'Got the predicate');
  has_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");};

subtest 'Replace operations with authentication' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->put("/bar/baz/bing/data", { 'Content-Type' => 'text/turtle',
												 Content => "<$base_uri/bar/baz/bing> <http://example.org/success> \"Replaced with triple\"\@en" });
  is($mech->status, 201, "Putting returns 201");
  my $model = check_content($mech);
  is($model->size, 1, 'Only one triple now');
  has_predicate('http://example.org/success', $model, 'Got the predicate');
  hasnt_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");
};


sub check_content {
  my $mech = shift;
  $mech->default_header('Accept' => 'application/rdf+xml');
  $mech->get_ok("/bar/baz/bing");
  is($mech->ct, 'application/rdf+xml', "Correct content-type");
  like($mech->uri, qr|/bar/baz/bing/data$|, "Location is OK");
  is_valid_rdf($mech->content, 'rdfxml', 'Returns valid RDF/XML');
  my $model = return_model($mech->content, $rxparser);
  has_subject($base_uri . 'bar/baz/bing', $model, "Subject URI in content");
  return $model;
}

sub return_model {
	my ($content, $parser) = @_;
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	return $retmodel;
}


done_testing();
