require 'securerandom'
require 'socket'
require 'json'
require 'yaml'

require_relative 'rexmessage'
require_relative 'remoteexecute'
require_relative 'rexsettings'

class RexApi < RexMessage

	def initialize( serverhost=nil )

		@serverhost = serverhost
		@serverport = RexSettings::SERVERPORT
		controllersid = RexSettings::CONTROLLERSID
		@logger = Logger.new( '/var/log/rex/rexapi.log')
		@logger.level = Logger::INFO
		@logger.sev_threshold = Logger::INFO
		@conversationid = SecureRandom.uuid()
		@command_mutex = Mutex.new

		puts "serverhost = #{@serverhost}, maestrosid = #{controllersid}"

		@server = TCPSocket.new( @serverhost, @serverport )
		if @server.nil?
			@logger.fatal( "Failed to create RexApi session" )
		else
			# Tell the server that we're a controller, and include the conversationid
			@server.puts( "#{controllersid}:#{@conversationid}")

			puts "RexApi instance created successfully"
		end
	end

	# Initialize a remote RexTaskClient session on the specified clienthost.
	def rex_init( taskname, clienthost )

		payload = Hash.new
		payload["taskname"] = "#{taskname}"
		payload["clienthost"] = "#{clienthost}"	

		return_sid = "#{@conversationid}"
		status = :success

		@command_mutex.synchronize do
			rex_send_command( @server, @conversationid, :rex_init, payload )
			status = read_task_status( @server, @conversationid )
			if status != :success
				return_sid = ""
			else
				return_sid = "#{@conversationid}"
			end
		end

		return return_sid
	end

	def rex_set_manifest( sessionid, manfile )

		status = nil

		@command_mutex.synchronize do

			#manifest = RemoteExecute::RexManifest.new(manfile)
			manifest = YAML::load_file(manfile)
			puts "Loaded manfile #{manfile}, manenv content follows"
			#pp manifest.manenv

			t = Time.now()
			manifest.manenv['EXEC_DATE'] = t.strftime("%Y%m%d_%H%M%S")
			puts "EXEC_DATE = #{manifest.manenv}"
			#puts "Inserted EXEC_DATE value, manenv content follows"
			#pp manifest.manenv

			File.open( 'protomanifest.yaml', 'w' ) do |file|
  			YAML.dump(manifest, file)
			end

			#pp manifest

			if not manifest.nil?
				#mandump = Marshal.dump( manifest )
				mandump = YAML::dump(manifest)

				#manifest.dump

				payload = Hash.new
				payload["manifest"] = "#{mandump}"

				puts "in rex_set_manifest, before rex_send_command"

				status = rex_send_command( @server, sessionid, :set_manifest, payload )
  			if status == :success
    			puts "Sent command to set manifest to #{manfile}"
					status = read_task_status( @server, sessionid )
  			else
    			puts "Failed to send command to set manifest to #{manfile}"
  			end

				puts "Returned from read_task_status, status = #{status}"
  			if status == :success
    			puts "Manifest is set to #{manfile}"
  			else
    			puts "Failed to set manifest to #{manfile}"
  			end
  		else
  			@logger.error( "Error, manifest object could not be created")
  			status = :failure
			end

		end
		puts "in rex_set_manifest, after rex_send_command"

		return status
	end

	def rex_start( sessionid )

		# Just call the rex_resume method
		status = rex_resume(sessionid, 1)

		if status != :success
			@logger.error( "Error, failed to send :rex_exec message")
		else
			status = read_task_status( @server, sessionid )
		end
		
		return status
	end

	def rex_task_wait
		puts "Waiting for task completion status"
		status = read_task_status(@server, @conversationid)
		#rex_kill(@conversationid)
		return status
	end

	def rex_resume( sessionid, stepnum )
		puts "In rex_resume, sessionid=#{sessionid}"

		status = nil

		@command_mutex.synchronize do
			payload = Hash.new
			payload["startstep"] = "#{stepnum}"

			# This is just the status of sending the command. Execution status
			# is fetched separately.
			status = rex_send_command( @server, sessionid, :exec_resume, payload )

			if status != :success
				@logger.error( "Error, failed to send :rex_exec message")
			else
				status = read_task_status( @server, sessionid )
			end
		end
		return status
	end

	def rex_get_status( sessionid )
		
		status = nil

		puts "in rex_get_status before synchronize"
		@command_mutex.synchronize do
			status = get_task_status( @server, sessionid )
		end
		puts "in rex_get_status after synchronize"

		return status
	end

	def rex_kill( sessionid )

		status = nil

		puts "in rex_kill before synchronize"
		@command_mutex.synchronize do
			@logger.info( "Killing client" )
			status = rex_send_command( @server, sessionid, :exec_abort )
		end
		puts "in rex_kill after synchronize"
		return status
	end

end
