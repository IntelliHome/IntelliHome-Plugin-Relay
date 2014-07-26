# NAME

IntelliHome::Plugin::Relay - Relay plugin for Google@Home

# SYNOPSIS

    $ ./intellihome-master -i Relay #for install
    $ ./intellihome-master -r Relay #for remove

# DESCRIPTION

IntelliHome::Plugin::Relay is a plugin that enables control of gpio's

# EVENTS

This plugin listen on the following events:

- GPIO\_MSG

    Listen to GPIO\_MSG, that can be emitted by the RPC server, it dispatch the command to the node (on/off)

- STATUS\_MSG

    Listen to STATUS\_MSG, it handles the update of the node's Gpio status into the database

# METHODS

- on

    Takes gpio tag as argument and send the request to the remote agent

- off

    Takes gpio tag as argument and send the request to the remote agent

# AUTHOR

mudler <mudler@dark-lab.net>

# COPYRIGHT

Copyright 2014- mudler

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
[IntelliHome](https://metacpan.org/pod/IntelliHome)
