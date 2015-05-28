#!/usr/bin/env ruby -w

require 'rexecute'

# Become deployer
Process::UID.grant_privilege(540)
Process::UID.change_privilege(540)

server = RexServer.new()
exit
