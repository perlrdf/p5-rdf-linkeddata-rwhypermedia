use 5.010001;
use strict;
use warnings;

package RDF::LinkedData::RWHypermedia;
use Moo;
use Types::Standard qw(Str);
use RDF::Trine qw(iri statement literal);
use Data::Dumper;

extends 'RDF::LinkedData';

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001_01';



=pod

=encoding utf-8

=head1 NAME

RDF::LinkedData::RWHypermedia - Experimental read-write hypermedia support for Linked Data

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

around 'response' => sub {
  my $orig = shift;
  my $self = shift;
  my @params = @_;
  my $uri = URI->new(shift);
  my $req = $self->request;
  my $response = Plack::Response->new;

  my $node = $self->my_node($uri);
  $self->log->info("Write operation is attempted for subject node: " . $node->as_string);
  if ($self->count($node) == 0) {
	 $response->status(404);
	 $response->headers->content_type('text/plain');
	 $response->body('HTTP 404: Unknown resource');
	 return $response;
  }
  
  unless (($self->type eq 'data') || $self->does_read_operation) {
	 $response->status(405);
	 $response->headers->content_type('text/plain');
	 $response->body("HTTP 405: Method not allowed.\nWrites can only be done against data information resources, not " . $self->type . ".\nTry getting ./controls\n");
	 return $response;
  }
  
  if ($self->type eq 'controls') {
	 if ($self->writes_enabled) {
		my $node = $self->my_node($uri);
		$self->log->info("Write operation is attempted for subject node: " . $node->as_string);
		unless ($self->is_logged_in) {
		  $response->status(401);
		  $response->headers->content_type('text/plain');
		  $response->body('HTTP 401: Authentication Required');
		  return $response;
		}
	 } else {
		$response->status(403);
		$response->headers->content_type('text/plain');
		$response->body("HTTP 403: Forbidden.\nServer is configured without writes.");
		return $response;
	 }
  }

  if (($self->type eq 'data') && (! $self->does_read_operation)) {
	 if ($self->is_logged_in) {
		# TODO: Merging goes here
		} else {
		  $response->status(401);
		  $response->headers->content_type('text/plain');
		  $response->body('HTTP 401: Authentication Required');
		}
  }

  return $orig->($self, @params);
};


around '_content' => sub {
 	my $orig = shift;
 	my $self = shift;
	my @params = @_;
	my $node = shift;
	my $type = shift;
	
	if ($type eq 'controls') {
		$self->log->debug('We generate a response for RW hypermedia controls');
		if ($self->writes_enabled) {
			my %output;
			my $rwmodel = RDF::Trine::Model->temporary_model;
			my $headers_in = $self->request->headers;
			$self->log->trace('Full headers we respond to: ' . $headers_in->as_string);
			
			my $data_iri = iri($node->uri_value . '/data');
			my $controls_iri = iri($node->uri_value . '/controls');
			$self->add_namespace_mapping(hm => 'http://example.org/hypermedia#');
			$self->guess_namespaces('rdf', 'void', 'rdfs');
			$self->add_namespace_mapping(hydra => 'http://www.w3.org/ns/hydra/core#');
			
			my $hm = $self->namespaces->hm;
			
			if ($self->is_logged_in) {
			  $self->log->debug('Logged in as: ' . $self->user);
			  
			  # TODO: Check ACL
			  $rwmodel->add_statement(statement($controls_iri,
															iri($self->namespaces->rdf->type),
															iri($hm->AffordancesDocument)));
			  $rwmodel->add_statement(statement($controls_iri,
															iri($self->namespaces->rdfs->comment),
															literal('This document describes what you can do in terms of write operations on ' . $data_iri->uri_value, 'en')));
			  $rwmodel->add_statement(statement($controls_iri,
															iri($hm->for),
															$data_iri));
			  $rwmodel->add_statement(statement($data_iri,
															iri($hm->canBe),
															iri($hm->mergedInto)));

			  my ($ctype, $s) = RDF::Trine::Serializer->negotiate('request_headers' => $headers_in,
																					base => $self->base_uri,
																					namespaces => $self->_namespace_hashref);
			  $output{content_type} = $ctype;
			  $output{body} = $s->serialize_model_to_string ( $rwmodel );
			} else {
			  # Shouldn't get here
			  die 'No user is logged in, probably a bug';
			}
			
			$self->log->trace("Message body is $output{body}" );

			return \%output
		} else {
			$self->log->warn('Controls were on, but not writes. Strange situation');
		}
	}
	return $orig->($self, @params);
};


has user => ( is => 'rw', isa => Str, lazy => 1, 
				  builder => '_build_user', 
				  predicate => 'is_logged_in');

sub _build_user {
	my $self = shift;
	my $uname = $self->request->user;
	return "urn:X-basicauth:$uname" if ($uname);
}

sub add_rw_pointer {
	my $self = shift;
	my $hmmodel = shift;
	my $uri = shift;
	my $exprefix = 'http://example.org/hypermedia#';
	$hmmodel->add_statement(statement(iri($uri->uri_value . '/data'),
												 iri($exprefix .  'toEditGoTo'),
												 iri($uri->uri_value . '/controls')));
}



=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-LinkedData-RWHypermedia>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut 

1;
