#!/usr/bin/env ruby
#
require_relative '../lib/rexecute/rexapi'

require 'optparse'
require 'yaml'
require 'pp'

# Hash for options passed in
options = {}

optparse = OptionParser.new do |opts|

  opts.banner = "Usage: ruby rextaskclient.rb [OPTIONS]"
  opts.separator ""
  opts.separator "Specific options"

  opts.on( '-c CONTROLLER', '--controller CONTROLLER', 'controller CONTROLLER' ) do |value|
    options[:controller] = value
  end

  opts.on( '-h HOST', '--host HOST', 'host HOST' ) do |value|
    options[:host] = value
  end

  opts.on( '-t TASKNAME', '--taskname TASKNAME', 'taskname TASKNAME' ) do |value|
    options[:taskname] = value
  end

  opts.on( '-e EXECFILE', '--execfile EXECFILE', 'execfile EXECFILE' ) do |value|
    options[:execfile] = value
  end

  opts.on( '-x EXECARGS', '--execargs ARGS', 'execargs EXECARGS' ) do |value|
    pp value
    options[:execargs] = value
  end

end

optparse.parse!

controller = options[:controller]
host = options[:host]
taskname = options[:taskname]
execfile = options[:execfile]
execargs = options[:execargs]

if host.nil? || taskname.nil? || execfile.nil?
  abort "Error, must supply host, taskname, and execfile"
end

puts "execargs = #{execargs}"
puts "execargs.class = #{execargs.class}"

puts "Starting remote execution of task #{taskname} on server #{host}"

`env`

# Get a REX API object and trigger the manifest execution
maestro = RexApi.new("#{controller}")

puts "API created, calling rex_init"

sessionid = maestro.rex_init(taskname, host)

if sessionid.empty?
  puts "Error in initializing rex client session"
  abort
else
  puts "rex_init call succeeded, sessionid=#{sessionid}"
end

status = :success

puts "Setting manifest to #{execfile}"
status = maestro.rex_set_manifest(sessionid, execfile, execargs)

if status != :success
  puts "Failed to set manifest for client to #{manifestfile}"
  abort
end

puts "Manifest for client set to #{execfile}, executing task"

status = maestro.rex_start(sessionid)
if status == :success
  puts "Workflow execution initiated"
else
  puts "Initiation of workflowflow failed"           
  abort
end

status = maestro.rex_task_wait
if status == :success
  puts "Task #{taskname} succeeded for server #{host}"
  exit
else
  puts "Task #{taskname} failed for server #{host}"
  abort
end
