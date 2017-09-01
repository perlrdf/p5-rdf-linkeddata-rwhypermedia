use 5.010001;
use strict;
use warnings;

package RDF::LinkedData::RWHypermedia;
use Moo;
use Types::Standard qw(Str);
use RDF::Trine qw(iri statement);

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

	if ($self->writes_enabled) {
		my $rwmodel = RDF::Trine::Model->temporary_model;
		my $headers_in = $self->request->headers;
		$self->log->trace('Full headers we respond to: ' . $headers_in->as_string);
		
		my $node = $self->my_node;
		my $data_iri = iri($node->uri_value . '/data');
		my $controls_iri = iri($node->uri_value . '/controls');
		$self->add_namespace_mapping(hm => 'http://example.org/hypermedia#');
		my $hm = $self->namespaces->hm;

		if ($self->is_logged_in) {
			$self->log->debug('Logged in as: ' . $self->user);
			# TODO: Check ACL
			if ($self->type eq 'controls') {
				$rwmodel->add_statement(statement($controls_iri,
												$self->namespaces->rdf->type,
												$hm->AffordancesDocument));
												


			} else {
				 $self->log->debug('No user is logged in');
				 # 		# TODO: check authz
				 # 		if ($self->type eq 'data' || $self->type eq 'page') {
				 # 			# We tell the user where they may authenticate
				 
				 # 		}
				 # 	}
				 
				 # 			# if($type eq 'data' && $self->is_logged_in) {
				 # 			# 	$self->add_auth_levels($self->check_authz($self->user, $node->uri_value . '/data'));
				 # 			# }
			 }
		}
	}
	return $orig->($self, @_);
};


has user => ( is => 'ro', isa => Str, lazy => 1, 
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
