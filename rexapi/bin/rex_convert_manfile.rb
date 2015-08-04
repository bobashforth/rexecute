#!/usr/bin/env ruby
#

require 'yaml'
require 'optparse'
require 'pp'

require 'rexcore'

# Hash for options passed in
options = {}

optparse = OptionParser.new do |opts|

  opts.banner = "Usage: ruby rex_convert_manfile.rb [OPTIONS]"
  opts.separator ""
  opts.separator "Specific options"

  opts.on( '-m MANFILE', '--manfile MANFILE', 'manfile MANFILE' ) do |value|
    options[:manfile] = value
  end

  opts.on( '-f flowman', '--flowman FLOWMAN', 'flowman FLOWMAN' ) do |value|
    options[:flowman] = value
  end

end

optparse.parse!

manfile = options[:manfile]
flowman = options[:flowman]

if manfile.nil? or flowman.nil?
  abort "Error, manifest name and flow manifest name must be provided"
end

manifest = RexCore::RexManifest.new()

if manifest.nil?
	puts "Error creating flow manifest object, exiting."
	exit 1
else
  manifest.manfile_initialize(manfile)
end

puts "Loaded manfile lib/#{manfile}, manifest flow object follows"
pp manifest

File.open( flowman, 'w' ) do |file|
  YAML.dump(manifest, file)
end

exit 0
