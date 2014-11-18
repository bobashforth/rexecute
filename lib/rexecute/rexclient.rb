require_relative 'rexmessage'
require_relative 'rexsettings'
require_relative 'remoteexecute'

require 'optparse'
require 'socket'
require 'json'
require 'yaml'

class RexClient < RexMessage

  attr_accessor :session_id

  def initialize( serverhost, sessionid, taskname )
    @sessionid = sessionid
    port = RexSettings::SERVERPORT
    @logger = Logger.new( '/var/log/rex/rexclient.log')
    @logger.sev_threshold = Logger::INFO
    @logger.level = Logger::INFO
    @server = TCPSocket.new( serverhost, port )
    @task_state = :init
    @task_status = :success

    @manifest = nil
    @taskname = nil

    listen
    @response.join
  end

  def listen
    #Thread::abort_on_exception = true
    @response = Thread.new do

      @logger.info( "In RexClient::listen" )
      # The server will be expecting the sessionid as part of the
      # initial handshake. If this sessionid has not been registered
      # with the server, the connection will be dropped.
      @server.puts( "TaskClient:#{@sessionid}" )

      # Sending status back is a response to the rex_init command which spawned
      # this client session
      rex_send_status( @server, @sessionid, :success )

      loop {
        msg = rex_get_message( @server )
        @logger.info( "In rexclient::listen, sessionid = #{@sessionid}, msg = #{msg}")

        if msg.nil? or msg.empty?
          @logger.error( "Error, received empty or nil message" )
        else
          status = dispatch( msg )
          if status != :success
            @logger.error( "Error in dispatching message #{msg}" )
          else
            @logger.info( "rexclient: dispatched message #{msg}, status is \"#{status}\"" )
          end
          @task_status = status
        end
      }
    end
  end  

  def dispatch( msg )

    puts "In RexTaskClient::dispatch"
    if msg.nil?
      puts "Empty or nil message, exiting"
      exit
    end

    # Dispatch of each message is based on the message type
    mtype = msg["message_type"].to_sym
    status = :success

    case mtype
    when :set_manifest
      puts "RexClient, in :set_manifest case, msg = #{msg}"
      if not msg["manifest"].nil?
        mandump = msg["manifest"]
        #@manifest = Marshal.load( mandump )
        @manifest = YAML::load( mandump )
        @manifest.dump

        if @manifest.nil?
          status = :failure
          puts "RexClient: set_manifest failed"
        else
          status = :success
          puts "RexClient: set_manifest succeeded"
        end
        status = rex_send_status( @server, @sessionid, "#{status}" )
      else           
        status = rex_send_status( @server, @sessionid, :failure )
      end
    when :get_task_state
      puts "in case :get_task_state"
      pp msg

    when :get_task_status
      rex_send_status( @server, @sessionid, @task_status )

    when :exec_start
      puts "in case :exec_start"
      status = exec_start( msg )
      status = rex_send_status( @server, @sessionid, status )

    when :exec_resume
      puts "in case :exec_resume"
      startstep = msg["startstep"]
      status = exec_resume( msg, startstep )
      status = rex_send_status( @server, @sessionid, status )

    when :exec_abort
      puts "Received abort message, terminating client session"
      exit 0

    when :status_ack
      puts "in case :status_ack"
      raise "Invalid message for task client"

    else
      puts "Error, invalid message type"
      status = :failure

    end

    return status
  end

  def exec_start( msg )
    startstep = 1
    status = exec_resume( msg, startstep )
    return status
  end

  def exec_resume( msg, startstep )

    actions = @manifest.manactions
    retstatus = :success
    actions.each do |action|
      puts "Executing stepnum #{action.stepnum}: \"#{action.label}\""
      pid = spawn( @manifest.manenv, action.command )
      puts "Spawned pid #{pid}."
      retpid, status = Process.waitpid2( pid )
      retstatus = status.exitstatus
      puts "Process #{pid} completed with status #{retstatus}"
      if "#{retstatus}" != "#{action.success_status}"
        break
      else
        retstatus = :success
      end
      #end
    end

    return retstatus
    
  end

end

