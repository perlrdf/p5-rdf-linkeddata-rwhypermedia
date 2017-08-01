use 5.010001;
use strict;
use warnings;

package RDF::LinkedData::RWHypermedia;
use Moo;
use Types::Standard qw(Str);

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




# around 'response' => sub {
# 	my $orig = shift;
# 	my $self = shift;
# 	my $origresponse = $orig->($self, @_);
# 	warn Data::Dumper::Dumper($origresponse);
# 	my $headers_in = $self->request->headers;
# 	$self->log->trace('Full headers we respond to: ' . $headers_in->as_string);


# 	if ($self->is_logged_in) {
# 		$self->log->debug('Logged in as: ' . $self->user);
# 	} else {
# 		$self->log->debug('No user is logged in');
# 		# TODO: check authz
# 		if ($self->type eq 'data' || $self->type eq 'page') {
# 			# We tell the user where they may authenticate
			
# 		}
# 	}

# 			# if($type eq 'data' && $self->is_logged_in) {
# 			# 	$self->add_auth_levels($self->check_authz($self->user, $node->uri_value . '/data'));
# 			# }
# 	return $orig->($self, @_);
# };


has user => ( is => 'ro', isa => Str, lazy => 1, 
				  builder => '_build_user', 
				  predicate => 'is_logged_in');

sub _build_user {
	my $self = shift;
	my $uname = $self->request->user;
	return "urn:X-basicauth:$uname" if ($uname);
}

sub add_rw_controls {
	my $self = shift;
	my $hmmodel = shift;
	my $data_iri = shift;
	my $exprefix = 'http://example.org/hypermedia#';
	if ($self->is_logged_in) {
		$hmmodel->add_statement($data_iri,
										iri($exprefix . 'canBe'),
										iri($exprefix . 'mergedInto'));
	} else {
		$hmmodel->add_statement($data_iri,
										iri($exprefix .  'toEditAuthAt'),
										iri($self->base_uri . '/auth'));
	}
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
