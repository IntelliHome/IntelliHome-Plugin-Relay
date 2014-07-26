package IntelliHome::Plugin::Relay;

=encoding utf-8

=head1 NAME

IntelliHome::Plugin::Relay - Relay plugin for Google@Home

=head1 SYNOPSIS

  $ ./intellihome-master -i Relay #for install
  $ ./intellihome-master -r Relay #for remove

=head1 DESCRIPTION

IntelliHome::Plugin::Relay is a plugin that enables control of gpio's

=head1 EVENTS

This plugin listen on the following events:

=over

=item GPIO_MSG

Listen to GPIO_MSG, that can be emitted by the RPC server, it dispatch the command to the node (on/off)

=item STATUS_MSG

Listen to STATUS_MSG, it handles the update of the node's Gpio status into the database

=back

=head1 METHODS

=over

=item on

Takes gpio tag as argument and send the request to the remote agent

=item off

Takes gpio tag as argument and send the request to the remote agent

=back

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO
L<IntelliHome>

=cut

use strict;
use 5.008_005;
our $VERSION = '0.01';
use Moo;
use IntelliHome::Utils qw(load_module);
use IntelliHome::Connector qw(STATUS_MSG GPIO_MSG);
extends 'IntelliHome::Plugin::Base';

sub on {
    my $self = shift;
    my $Hypo = shift;
    my $tag  = join( " ", @{ $Hypo->result } );
    chomp $tag;
    $self->_command( $tag, "on" );
}

sub off {
    my $self = shift;
    my $Hypo = shift;
    my $tag  = join( " ", @{ $Hypo->result } );
    chomp $tag;
    $self->_command( $tag, "off" );
}

sub _command {
    my $self   = shift;
    my $tag    = shift;
    my $action = shift;
    $self->IntelliHome->Output->failback->info("Searching $tag GPIO");
    my @GPIOs = $self->IntelliHome->Backend->search_gpio($tag);
    $self->IntelliHome->Output->failback->error("No gpio could be found")
        and return 0
        unless @GPIOs > 0;
    foreach my $GPIO (@GPIOs) {
        $self->IntelliHome->Output->failback->error(
            "No suitable driver could be found for " . $GPIO->pin_id )
            and next
            unless $GPIO->driver;
        eval {
            load_module( $GPIO->driver );
            my $Driver = $GPIO->driver;
            if ( @{ $GPIO->pins } > 0 ) {
                $Driver->new(
                    onPin  => $GPIO->pin_id,
                    offPin => shift @{ $GPIO->pins },
                    Connector =>
                        IntelliHome::Connector->new( Node => $GPIO->node )
                );
            }
            else {
                $Driver->new(
                    Pin => $GPIO->pin_id,
                    Connector =>
                        IntelliHome::Connector->new( Node => $GPIO->node )
                );
            }
            $Driver->$action;
        };
        if ($@) {
            $self->IntelliHome->Output->error($@) and return 0;
        }
    }
    return 1;
}

sub _status {
    my $self = shift;
    my $id   = shift; #we should retrieve it from pins or pin_id in the schema
    my $rs   = shift; #return status
    my $GPIO = $self->Parser->Backend->search_gpio_pin($id);
    $GPIO->status($rs);
    return $GPIO->can("update") ? $GPIO->update : $GPIO->save;
}

sub install {
    my $self = shift;
    ############## closing ##############
    $self->Parser->Backend->installPlugin(
        {   regex         => 'close\s+(.*)',    #We have one global match here
            language      => "en",
            plugin_method => "off"
        },
        {   regex         => 'chiudi\s+(.*)',   #We have one global match here
            language      => "it",
            plugin_method => "off"
        }
    );
    ############## opening ##############
    $self->Parser->Backend->installPlugin(
        {   regex         => 'open\s+(.*)',     #We have one global match here
            language      => "en",
            plugin_method => "on"
        },
        {   regex         => 'apri\s+(.*)',     #We have one global match here
            language      => "it",
            plugin_method => "on"
        }
    );

    $self->app->event->on(

        #Handling RPC request
        # RPC requests are processed in $tag, on/off
        GPIO_MSG =>
            sub { shift->IntelliHome->Plugins->{"Relay"}->_command(@_); }
    );

    $self->app->event->on(

        #Handling STATUS , it's in the form : id, response_status
        STATUS_MSG => sub {
            shift->IntelliHome->Plugins->{"Relay"}->_status(@_);
        }
    );

    return 0;
}

1;
__END__
