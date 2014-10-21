package Magpie::Transformer;
{
  $Magpie::Transformer::VERSION = '1.131280';
}
# ABSTRACT: Magpie Pipeline Transformer Base Class

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

# abstract base class for all transformer;

has '+_trait_namespace' => (
    default => 'Magpie::Plugin::Transformer'
);

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    coerce      => 1,
    default     => sub { return $_[0]->resolve_internal_asset( service => 'default_resource') },
);

# SEEALSO: Magpie

1;


=pod

=head1 NAME

Magpie::Transformer - Magpie Pipeline Transformer Base Class

=head1 VERSION

version 1.131280

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
