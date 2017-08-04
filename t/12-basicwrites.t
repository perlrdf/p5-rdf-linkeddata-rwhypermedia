#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;
use Test::RDF;
use Log::Any::Adapter;
use Module::Load::Conditional qw[can_load];
use RDF::Trine qw(iri);

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

my $file = $Bin . '/data/basic.ttl';

my $exprefix = 'http://example.org/hypermedia#';

BEGIN {
    use_ok('RDF::LinkedData');
    use_ok('RDF::LinkedData::RWHypermedia');
    use_ok('RDF::Trine::Parser');
    use_ok('RDF::Trine::Model');
 }

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $ld = RDF::LinkedData::RWHypermedia->new(model => $model, 
														  base_uri=>$base_uri, 
														  writes_enabled => 1,
														  hypermedia => 1);

isa_ok($ld, 'RDF::LinkedData');
isa_ok($ld, 'RDF::LinkedData::RWHypermedia');
cmp_ok($ld->count, '>', 0, "There are triples in the model");

subtest "Get /foo" => sub {
    $ld->request(Plack::Request->new({}));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/foo/data$|, "Location is OK");
};

my $authurl;

subtest "Get /foo/data" => sub {
    $ld->type('data');
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 200, "Returns 200");
    my $model = RDF::Trine::Model->temporary_model;
    my $parser = RDF::Trine::Parser->new( 'turtle' );
    $parser->parse_into_model( $base_uri, $response->body, $model );
    has_literal('This is a test', 'en', undef, $model, "Test phrase in content");
	 has_subject($base_uri . '/foo/data', $model, 'Data URI in content');
	 has_predicate($exprefix . 'toEditAuthAt', $model, 'Auth predicate in content');
	 $authurl = ($model->objects_for_predicate_list ( iri($base_uri . '/foo/data'), iri($exprefix . 'toEditAuthAt')));
	 isa_ok($authurl, 'RDF::Trine::Node::Resource', 'Authentication URL is a resource');
	 ok($authurl->equal(iri($base_uri . '/auth')), 'Authentication URL is correct');
};

subtest "Get authurl" => sub {
	my $response = $ld->response($base_uri . '/auth');
	isa_ok($response, 'Plack::Response');
	is($response->status, 401, "Returns 401");
};


done_testing;
