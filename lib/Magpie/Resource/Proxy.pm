package Magpie::Resource::Proxy;
# ABSTRACT: .
$Magpie::Resource::Proxy::VERSION = '1.141660';
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use LWP::UserAgent;
use HTTP::Request;
use Plack::Response;

has user_agent => (
    is          => 'ro',
    isa         => 'LWP::UserAgent',
    default     => sub { LWP::UserAgent->new },
);

has [qw(scheme host path method port)] => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);

has url => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);

has headers => (
    is          => 'rw',
    isa         => 'HTTP::Headers',
    lazy_build  => 1,
);

has content => (
    is          => 'rw',
    lazy_build  => 1,
);

sub _build_scheme {
    shift->plack_request->scheme;
}

sub _build_host {
    shift->plack_request->uri->host;
}

sub _build_path {
    shift->plack_request->path;
}

sub _build_method {
    shift->plack_request->method;
}

sub _build_content {
    shift->plack_request->content;
}

sub _build_port {
    shift->plack_request->port;
}

sub _build_headers {
    shift->plack_request->headers;
}

sub _build_url {
    my $self = shift;
    $self->scheme . '://' . $self->host . ':' . $self->port . $self->path;
}


sub proxy {
    my $self = shift;
    my $ctxt = shift;
    my $url = $self->url;
    my $request = HTTP::Request->new( $self->method, $self->url, $self->headers, $self->content );
    my $ua = $self->user_agent;
    my $lwp_response = $ua->request($request);
    my $resp = Plack::Response->new($lwp_response->code, $lwp_response->headers->clone, $lwp_response->content);
    $self->data($resp);
    return OK;
}

around [HTTP_METHODS] => sub {
    my $orig = shift;
    my $self = shift;
	$self->parent_handler->resource($self);
	return $self->proxy(@_);
};

1;



=pod

=head1 NAME

Magpie::Resource::Proxy - .

=head1 VERSION

version 1.141660

# SEALSO: Magpie, Magpie::Resource

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
