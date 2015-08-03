#!/usr/bin/env ruby -w

require 'socket'
require 'logger'

require 'rexcore'

include RexCore

class RexServer < RexMessage

  def initialize( port=RexSettings::SERVERPORT )
    @server = TCPServer.new( port )
    @serverhost = Socket.gethostname
    @logger = Logger.new( '/var/log/rex/rexserver.log' )
    @logger.level = Logger::WARN
    @logger.sev_threshold = Logger::INFO
    @manlines = nil

    # This array lists uuids which have been provided to new RexTaskClient
    # instances. Any clients contacting us with a sessionid which is not
    # in this list are rejected.
    # Seed the array with the master sessionid.
    @controllersid = RexSettings::CONTROLLERSID
    @clients = Hash.new
    @controllers = Hash.new
    @conversation_mutex = Mutex.new

    run
  end
 
  def run
    loop {

      #Thread::abort_on_exception = true
      Thread.start(@server.accept) do | client |
        @logger.info( "Client session started, waiting for sessionid" )
        sessionid = client.gets.strip!

        client_type, sid = "#{sessionid}".split(/:/)

        if "#{client_type}" == "#{@controllersid}"
          sessiontype = :controller
          sessionid = "#{sid}"
          @conversation_mutex.synchronize do
            @controllers["#{sessionid}"] = client
          end
          @logger.info("New controller session accepted, sessionid #{sessionid}")

          # Get a message from the controller; it has to be a rex_init message
          # by definition
          msg = rex_get_message( client )
          @logger.info("rexserver: Received initial controller message")
          if msg["message_type"].to_sym == :rex_init
            status = rex_init( msg )
            status = rex_send_status( @controllers["#{sessionid}"], sessionid, status )
            if status != :success
              @logger.fatal( "Error, failed to send status of rex_init to controller")
              @conversation_mutex.synchronize do
                @controllers.delete("#{sessionid}")
              end
              Thread.kill self
            end
          else
            status = :failure
            @logger.fatal( "Error, initial controller message was not rex_init: #{msg}")
            @conversation_mutex.synchronize do
              @controllers.delete("#{sessionid}")
            end
            Thread.kill self
          end
          if status == :success
            # We have a mated controller-client pair, proceed to process commands.
            # (The sessionid will identify the pair.)
            process_commands( sessionid )
          end

        else
          @logger.info("This is a client session")
          sessiontype = :taskclient
          if not @controllers.has_key?( "#{sid}" )
            @logger.fatal( "Error, sessionid #{sessionid} has not been registered" )
            Thread.kill self
          elsif @clients.has_key?( "#{sid}" )
            @logger.fatal( "This sessionid is already in use" )
            Thread.kill self
          else
            @conversation_mutex.synchronize do
              @clients["#{sid}"] = client
            end
            @logger.info("New client session accepted, sessionid #{sid}")
            pp @clients
          end
        end

        @logger.info( "Connection established" )

      end
    }.join
  end

  def process_commands( sessionid )
    # For each conversation, we loop waiting for and processing
    # commands. Each command will specifically request return
    # status from the client, so no client socket processing appears here.
    loop {
      @logger.info("In process_commands, top of loop")

      msg = rex_get_message( @controllers["#{sessionid}"] )

      status = dispatch_command( msg )
      
      if status != :success
        @logger.error( "Failure status returned from dispatch method")
      end
    }
  end

  def rex_init( msg )
    @logger.info("In rex_init")

    taskname = msg["taskname"]
    sessionid = msg["sessionid"]
    clienthost = msg["clienthost"]
    id = msg["id"]

    command = "startrexclient.rb -h #{@serverhost} -s #{sessionid} -t #{taskname}"
    wholecommand = "ssh -nf #{clienthost} \'script -f -c \"#{command}\"  Job_#{id}.log\' &>/dev/null &"
    @logger.info( "Command to client is #{wholecommand}" )

    status = system( "#{wholecommand}" )
    if status != true
      @logger.error( "Error, could not create new remote client session" )
      return :failure
    end

    # If the client is detected, get client status for confirmation, which
    # lets it block appropriately. Note that for rex_init, the client will
    # send this status without need for a request.
    status = rex_wait_for_client( sessionid )
    if status == :success
      status = read_task_status( @clients["#{sessionid}"], sessionid )
    end

    return status
  end


  def set_manifest( msg )

    payload = Hash.new
    mandump = msg["manifest"]
    payload["manifest"] = "#{mandump}"
    @logger.info( "rexserver, in set_manifest before sending message" )

    sessionid = msg["sessionid"]

    status = rex_send_message( @clients["#{sessionid}"], sessionid, :set_manifest, payload )
    @logger.info( "rexserver, in set_manifest after sending message")
    if status != :success
      @logger.error( "Error in sending :set_manifest message" )
    else
      status = read_task_status( @clients["#{sessionid}"], msg )
    end

    return status 
  end

  def dispatch_command( msg )

    @logger.info("In dispatch_command")
    # Dispatch of each message is based on the message type
    mtype = msg["message_type"].to_sym
    sessionid = msg["sessionid"]

    @logger.info("mtype is #{mtype}")
    @logger.info("sessionid is #{sessionid}")

    status = :success

    case mtype

    when :set_manifest
      @logger.info("in :set_manifest case, msg = #{msg}")
      status = set_manifest( msg )
      status = rex_send_status( @controllers["#{sessionid}"], sessionid,  status )

    when :exec_start
      @logger.info("in :exec_start case, msg = #{msg}")
      status = rex_send_message( @clients["#{sessionid}"], sessionid, :exec_start )
      status = rex_send_status( @controllers["#{sessionid}"], sessionid,  status )

    when :exec_resume
      @logger.info("in :exec_resume case, msg = #{msg}")
      startstep = msg["startstep"]
      payload = Hash.new
      payload["startstep"] = "#{startstep}"

      status = rex_send_message( @clients["#{sessionid}"], sessionid, :exec_resume, payload )
      status = rex_send_status( @controllers["#{sessionid}"], sessionid,  status )

    when :exec_kill
      # We need to tread carefully here. Wait for the status to return, trusting that
      # the client will have committed suppuku as requested. Note that the client socket
      # may be closed already, so disregard the status value.
      status = rex_send_message( @clients["#{sessionid}"], sessionid, :exec_kill )

      # Now send the status back to the caller, and only then remove the entries
      # for this conversation from @controllers and @clients hashes.
      status = rex_send_status( @controllers["#{sessionid}"], sessionid,  :success )
      @conversation_mutex.synchronize do
        begin
          @logger.info("Deleting conversation #{sessionid}")
          @clients.delete("#{sessionid}")
          @controllers.delete("#{sessionid}")
          @logger.info("@clients hash count: #{@clients.length}")
          @logger.info("@controllers hash count: #{@controllers.length}")
        rescue => e
          @logger.info("Error deleting conversation hash entries")
          pp e
        end
      end

    when :status_ack
      status = msg["status"].to_sym
      rex_send_status( @controllers["#{sessionid}"], sessionid,  status )

    when :get_task_status
      status = get_task_status( @clients["#{sessionid}"], sessionid )
      rex_send_status( @controllers["#{sessionid}"], sessionid,  status )

    else
      @logger.error( "Error, invalid message type \"#{mtype}\"" )
      status = :failure
    end
    return status
  end

  def rex_wait_for_client( sessionid )

    status = :success

    i = 0
    until i > 9 or not @clients["#{sessionid}"].nil? do
      sleep 6
      i += 1
    end

    pp @clients["#{sessionid}"]

    if @clients["#{sessionid}"].nil?
      status = :failure
    end

    return status.to_sym
  end
end
 


