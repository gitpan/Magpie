package Magpie::Dispatcher::Env;
{
  $Magpie::Dispatcher::Env::VERSION = '1.131250';
}
#ABSTRACT: INCOMPLETE - Placeholder for future Dispatcher Role

use Moose::Role;

requires 'map_events';

has event_mapping => (
    is        => 'ro',
    isa       => 'HashRef',
    builder   => 'map_events',
);

sub load_queue {
    my $self = shift;
    my $ctxt = shift;
    my $mapping = $self->event_mapping;

    my @event_names = ();
    my $env = $self->plack_request->env;

    foreach my $event ( keys( %{$mapping} )) {
        my $val = $mapping->{$event};

    }
}

1;



=pod

=head1 NAME

Magpie::Dispatcher::Env - INCOMPLETE - Placeholder for future Dispatcher Role

=head1 VERSION

version 1.131250

#SEEALSO: Magpie

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
