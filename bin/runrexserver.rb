#!/usr/bin/env ruby -w

require 'rexecute'

# Become deployer. This is necessary because using the Daemons gem to run the rex server as a service
# makes us the root user, and we need deployer passwordless access.
Process::UID.grant_privilege(540)
Process::UID.change_privilege(540)

server = RexServer.new()
exit
