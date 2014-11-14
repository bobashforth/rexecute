#!/usr/bin/env ruby
#
require_relative '../lib/rexecute/rexclient'

require 'optparse'

# Hash for options passed in
options = {}

optparse = OptionParser.new do |opts|

  opts.banner = "Usage: ruby rextaskclient.rb [OPTIONS]"
  opts.separator ""
  opts.separator "Specific options"

  opts.on( '-h APP', '--host HOST', 'host HOST' ) do |value|
    options[:host] = value
  end

  opts.on( '-s SESSIONID', '--sessionid SESSIONID', 'sessionid SESSIONID' ) do |value|
    options[:sessionid] = value
  end

  opts.on( '-t TASKNAME', '--taskname TASKNAME', 'taskname TASKNAME' ) do |value|
    options[:taskname] = value
  end

end

optparse.parse!

host = options[:host]
sessionid = options[:sessionid]
taskname = options[:taskname]

if host.nil? or sessionid.nil?
  abort "Error, host and sessionid must be provided"
end

rex_task_client = RexClient.new( host, sessionid, taskname )


