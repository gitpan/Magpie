package Magpie::Resource::Kioku;
$Magpie::Resource::Kioku::VERSION = '1.141660';
# ABSTRACT: INCOMPLETE - Resource implementation for KiokuDB datastores.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Try::Tiny;
use KiokuDB;
use Class::Load;

has data_source => (
    is         => 'ro',
    isa        => 'KiokuDB',
    lazy_build => 1,
);

has wrapper_class => (
    isa      => "Str",
    is       => "ro",
    required => 1,
    default  => 'MagpieGenericWrapper',
);

has dsn => (
    isa       => "Str",
    is        => "ro",
    predicate => "has_dsn",
);

has extra_args => (
    isa       => "HashRef|ArrayRef",
    is        => "ro",
    predicate => "has_extra_args",
);

has typemap => (
    isa       => "KiokuDB::TypeMap",
    is        => "ro",
    predicate => "has_typemap",
);

has _kioku_scope => (
    is  => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

has username => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_username',
);

has password => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_password',
);

sub _connect_args {
    my $self = shift;
    my @args = ( $self->dsn || die "dsn is required" );

    if ( $self->has_username ) {
        push @args, user => $self->username;
    }

    if ( $self->has_password ) {
        push @args, password => $self->password;
    }

    if ( $self->has_typemap ) {
        push @args, typemap => $self->typemap;
    }

    if ( $self->has_extra_args ) {
        my $extra = $self->extra_args;

        if ( ref($extra) eq 'ARRAY' ) {
            push @args, @$extra;
        }
        else {
            push @args, %$extra;
        }
    }

    \@args;
}

sub _build_data_source {
    my $self = shift;
    my $k    = undef;

    try {
        $k = $self->resolve_asset( service => 'kioku_dir' );
    }
    catch {
        try {
            $k = KiokuDB->connect( @{ $self->_connect_args } );
        }
        catch {
            my $error = "Could not connect to Kioku data source: $_\n";
            warn $error;
            $self->set_error( { status_code => 500, reason => $error } );
        };
    };

    return undef if $self->has_error;
    $self->_kioku_scope( $k->new_scope );
    return $k;
}

sub GET {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource($self);
    my $req = $self->request;

    my $path = $req->path_info;
    my $id = $self->get_entity_id($ctxt);

    if ($path =~ /\/$/  && !$id ) {
        $self->state('prompt');
        return OK;
    }

    my $data = undef;

    try {
        ($data) = $self->data_source->lookup($id);
    }
    catch {
        my $trace = $_;
        if (ref($trace)) {
            $trace = $trace->as_string;
        }
        my $error = "Could not GET data from Kioku data source: $trace\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    unless ($data) {
        $self->set_error({ status_code => 404, reason => 'Resource not found.'});
        return OK;
    }

    $self->data($data);
    return OK;
}

sub POST {
    my $self = shift;
    $self->parent_handler->resource($self);
    my $req = $self->request;

    my $to_store = undef;

    my $wrapper_class = $self->wrapper_class;

    # XXX should check for a content body first.
    my %args = ();

    if ( $self->has_data ) {
        %args = %{ $self->data };
        $self->clear_data;
    }
    else {
        for ( $req->param ) {
            $args{$_} = $req->param($_);
        }
    }

    # permit POST to update if there's an entity ID.
    # XXX: Should this go in an optional Role?
    if (my $existing_id = $self->get_entity_id) {
        my $existing = undef;
        try {
            ($existing) = $self->data_source->lookup($existing_id);
        }
        catch {
            my $error = "Could not fetch data from Kioku data source for POST editing if entity with ID $existing_id: $_\n";
            $self->set_error( { status_code => 500, reason => $error } );
        };

        return OK if $self->has_error;

        if ($existing) {
            foreach my $key (keys(%args)) {
                $existing->$key( $args{$key} );
            }

            try {
                $self->data_source->txn_do( sub {
                    $self->data_source->store($existing);
                });
            }
            catch {
                my $error = "Error updating data entity with ID $existing_id: $_\n";
                $self->set_error( { status_code => 500, reason => $error } );
            };

            return OK if $self->has_error;

            # finally, if it all went OK, say so.
            $self->state('updated');
            $self->response->status(204);
            return OK;
        }
    }

    # if we make it here there is no existing record, so make a new one.
    try {
        Class::Load::load_class($wrapper_class);
        $to_store = $wrapper_class->new(%args);
    }
    catch {
        my $error
            = "Could not create instance of wrapper class '$wrapper_class': $_\n";
        warn $error;
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return DECLINED if $self->has_error;

    my $id = undef;

    try {
        $self->data_source->txn_do( sub {
            $id = $self->data_source->store($to_store);
        });
    }
    catch {
        my $error = "Could not store POST data in Kioku data source: $_\n";
        warn $error;
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return DECLINED if $self->has_error;

    # XXX: all of this needs to go in an abstract object downstream serializer
    # can figure stuff out
    my $path = $req->path_info;
    $path =~ s|^/||;
    $path =~ s|/$||;
    $self->state('created');
    $self->response->status(201);
    $self->response->header( 'Location' => $req->base . $path . "/$id" );
    return OK;
}

sub DELETE {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource( $self );
    my $req = $self->request;

    my $path = $req->path_info;

    if ( $path =~ /\/$/ ) {
        $self->state('prompt');
        return OK;
    }

    my $id = $self->get_entity_id($ctxt);

    # should we do a separate lookup to make sure the data is there?
    try {
        $self->data_source->txn_do( sub {
            $self->data_source->delete( $id );
        });
    }
    catch {
        my $error = "Could not delete data from Kioku data source: $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return OK if $self->has_error;
    $self->state('deleted');
    $self->response->status(204);
    return OK;
}


sub PUT {
    my $self = shift;
    $self->parent_handler->resource($self);
    my $req = $self->request;

    my $to_store = undef;

    my $wrapper_class = $self->wrapper_class;

    # XXX should check for a content body first.
    my %args = ();

    if ( $self->has_data ) {
        %args = %{ $self->data };
        $self->clear_data;
    }
    else {
        for ( $req->param ) {
            $args{$_} = $req->param($_);
        }
    }

    my $existing_id = $self->get_entity_id;

    unless ($existing_id) {
        $self->set_error({
            status_code => 400,
            reason => "Attempt to PUT without a definable entity ID."
        });
        return DONE;
    }


    my $existing = undef;
    try {
        ($existing) = $self->data_source->lookup($existing_id);
    }
    catch {
        my $error = "Could not fetch data from Kioku data source for PUT editing if entity with ID $existing_id: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    unless ($existing) {
        $self->set_error(404);
        return DONE;
    }

    foreach my $key (keys(%args)) {
        try {
            $existing->$key( $args{$key} );
        }
        catch {
            my $error = "Error updating property '$key' of Resource ID $existing_id: $_\n";
            $self->set_error( { status_code => 500, reason => $error } );
            last;
        };
    }


    return OK if $self->has_error;

    try {
        $self->data_source->txn_do(sub {
            my $scope = $self->data_source->new_scope;
            $self->data_source->store($existing);
        });
    }
    catch {
        my $error = "Error updating data entity with ID $existing_id: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    # finally, if it all went OK, say so.
    $self->state('updated');
    $self->response->status(204);
    return OK;
}


package MagpieGenericWrapper;
$MagpieGenericWrapper::VERSION = '1.141660';
sub new {
    my $proto = shift;
    my %args  = @_;
    return bless \%args, $proto;
}

1;



=pod

=head1 NAME

Magpie::Resource::Kioku - INCOMPLETE - Resource implementation for KiokuDB datastores.

=head1 VERSION

version 1.141660

# SEEALSO: Magpie, Magpie::Resource

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

