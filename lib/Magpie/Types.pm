package Magpie::Types;
{
  $Magpie::Types::VERSION = '1.140280';
}
# ABSTRACT: Common Magpie Type Constraints
use Moose::Role;
#use HTTP::Throwable::Factory;
use Magpie::Error;
use Moose::Util::TypeConstraints;
use Class::Load;

my %http_lookup = (
    300 => 'MultipleChoices',
    301 => 'MovedPermanently',
    302 => 'Found',
    303 => 'SeeOther',
    304 => 'NotModified',
    305 => 'UseProxy',
    307 => 'TemporaryRedirect',
    400 => 'BadRequest',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'NotFound',
    405 => 'MethodNotAllowed',
    406 => 'NotAcceptable',
    407 => 'ProxyAuthenticationRequired',
    408 => 'RequestTimeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'LengthRequired',
    412 => 'PreconditionFailed',
    413 => 'RequestEntityTooLarge',
    414 => 'RequestURITooLong',
    415 => 'UnsupportedMediaType',
    416 => 'RequestedRangeNotSatisfiable',
    417 => 'ExpectationFailed',
    418 => 'ImATeapot',
    500 => 'InternalServerError',
    501 => 'NotImplemented',
    502 => 'BadGateway,',
    503 => 'ServiceUnavailable',
    504 => 'GatewayTimeout',
    505 => 'HTTPVersionNotSupported',
);

subtype 'SmartHTTPError' => as 'Maybe[Object]';

coerce 'SmartHTTPError'
    => from 'HashRef'
        => via { Magpie::Error->new_exception($_) },
    => from 'Int'
        => via { my $name = code_lookup($_); return HTTP::Throwable::Factory->new_exception( $name => {}) },
    => from 'Str'
        => via { Magpie::Error->new_exception($_ => {}) },
;

sub code_lookup {
    my $numeric = shift;
    return defined( $http_lookup{$numeric} ) ? $http_lookup{$numeric} : $http_lookup{'500'};
}

subtype 'MagpieResourceObject' => as 'Maybe[Object]';

coerce 'MagpieResourceObject'
    => from 'HashRef'
        => via {
            my $args = $_;
            my $class = delete $args->{class};
            Class::Load::load_class( $class );
            $class->new( $args );
        },
    => from 'Str'
        => via {
            my $class = shift;
            Class::Load::load_class( $class );
            $class->new;
        },
;

# SEEALSO: Magpie

1;

__END__
=pod

=head1 NAME

Magpie::Types - Common Magpie Type Constraints

=head1 VERSION

version 1.140280

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

