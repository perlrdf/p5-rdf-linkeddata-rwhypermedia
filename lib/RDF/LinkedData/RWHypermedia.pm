use 5.010001;
use strict;
use warnings;

package RDF::LinkedData::RWHypermedia;
use Moo;

extends 'RDF::LinkedData';

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001_01';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::LinkedData::RWHypermedia - Experimental read-write hypermedia support for Linked Data

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

# around 'BUILD' => {

#  	if ($self->has_acl_config) {
# 		$self->log->debug('ACL config found with parameters: ' . Dumper($self->acl_config) );

# 		unless (can_load( modules => { 'RDF::ACL' => 0.100 })) {
# 			croak "RDF::ACL not installed. Please install or remove its configuration.";
# 		}

# 		$self->acl;
#  	} else {
# 		$self->log->info('No ACL config found');
# 	}
# };

# #	warn Dumper($self->acl_config);
# has acl => (is => 'ro', 
# 				isa => InstanceOf['RDF::ACL'], 
# 				builder => '_build_acl', 
# 				lazy => 1,
# 				handles => { check_authz => 'check' });

# sub _build_acl {
# 	my $self = shift;
# 	return RDF::ACL->new($self->acl_model);
# }

# has acl_config => (is => 'rw', isa=>HashRef, predicate => 'has_acl_config');


has user => ( is => 'ro', isa => Str, lazy => 1, builder => '_build_user', predicate => 'is_logged_in');

sub _build_user {
	my $self = shift;
	my $uname = $self->request->user;
	return "urn:X-basicauth:$uname" if ($uname);
}

around 'response' => {
	$self->log->trace('Full headers we respond to: ' . $headers_in->as_string);

	if ($self->is_logged_in) {
		$self->log->debug('Logged in as: ' . $self->user);
	} else {
		$self->log->debug('No user is logged in');
	}

			# if($type eq 'data' && $self->is_logged_in) {
			# 	$self->add_auth_levels($self->check_authz($self->user, $node->uri_value . '/data'));
			# }

};

sub replace {
	my $self = shift;
	my $uri = URI->new(shift);
	my $payload = $self->request->content || shift;
	my $response = Plack::Response->new;
	if ($payload) {
	  my $headers_in = $self->request->headers;
	  $self->log->debug('Will merge payload as ' . $headers_in->content_type);
	  eval {
		 my $parser = RDF::Trine::Parser->parser_by_media_type($headers_in->content_type);
		 $parser->parse_into_model($self->base_uri, $payload, $self->model);
	  };
	  if ($@) {
		 $response->status(400);
		 $response->content_type('text/plain');
		 $response->body("Couldn't parse the payload: $@");
		 return $response;
	  }
	}
	$response->status(204);
	return $response;
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

