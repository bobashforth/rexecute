#
# This module addresses remote execution (REX) functionality,
# to meet the needs of the Marketo
# 'Maestro' consolidated release tool.
#
# July 2014 Bob Ashforth, RelEng
#
require 'socket'                # Get sockets from stdlib
require 'pp'

module RemoteExecute

  # RexAction represents a single step in a manifest.
  class RexAction

  	attr_reader :stepnum
  	attr_reader :label
  	attr_reader :command
  	attr_reader :success_status

  	def initialize( stepnum, label, command, success_status )
  	  @stepnum = stepnum
  	  @label = label
  	  @command = command
  	  @success_status = success_status
  	end
  end

	class RexManifest

		attr_reader :manifestfile
		attr_reader :manactions

		def initialize( manfile )
	    @manifestfile = manfile
	    @manactions = []


		  # Use the original manifest format defined for mlm releases; fields are
		  # colon-delimited and defined as follows:
		  #
		  # f1 - Step number, not required but checked against actual sequence
		  # f2 - ack/noack, used for original screen menu but ignored here
		  # f3 - The return status expected when this command is executed
		  # f4 - The name/label used to identify this step
		  # f5 - The remainder of the line is the actual command (with args) issued
		  #
		  # At some point this module may use a redefined format; if the original format
		  # is still supported at that time, we'll either add a format specifier or infer
		  # the format by pattern-matching the file contents.
		  manlines = nil
			if File.exist?( manfile )
		  	File.open( manfile, "r" ) do | f |
		    	manlines = f.readlines()
		  	end
			else
		  	puts( "Error, file #{manfile} does not exist." )
		  	exit 1
			end

		  i = 0
			manlines.each do | l |
			  nexti = i + 1
			 	fields = l.chomp.split( ':' )
			 	if fields.length < 5
			 		break
			 	end
			  stepnum = fields[0]
			  label = fields[3]
			  command = fields[4]
			  success_status = fields[2]

			  if nexti.to_i != stepnum.to_i
			  	puts "INFO: Manifest step numbers are not in sequence"
			  	puts "stepnum: #{stepnum}, nexti: #{nexti}"
			  end

			  action = RexAction.new( stepnum, label, command, success_status )
			  @manactions[i] = action

			  i += 1
			end
		end

		def dump
			puts "\n\nManifest Dump:\n\n"
			puts "Manifest file: #{@manifestfile}\n"
			@manactions.each do |action|
				puts "stepnum: #{action.stepnum}"
				puts "label: #{action.label}"
				puts "success_status: #{action.success_status}"
				puts "command: #{action.command}"
			end
		end
	end
end




