require 'rexcore'

require 'optparse'
require 'socket'
require 'json'
require 'yaml'
require 'pp'
require 'open3'

include RexCore

module RexClient

  class RexClient < RexMessage

    attr_accessor :session_id

    def initialize( serverhost, sessionid, taskname )

      @sessionid = sessionid
      port = RexSettings::SERVERPORT
      system("sudo mkdir -p /var/log/rex/rexclient.log")
      system("sudo chown deployer.marketo /var/log/rex/rexclient.log")
      @logger = Logger.new('/var/log/rex/rexclient.log')
      @logger.sev_threshold = Logger::INFO
      @logger.level = Logger::INFO
      @server = TCPSocket.new( serverhost, port )
      @task_state = nil
      @task_status = nil

      @manifest = nil
      @taskname = taskname

      @execthread = nil

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
          if @task_state == :completed
            break
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
          #@manifest.dump

          if @manifest.nil?
            @task_status = :failure
            puts "RexClient: set_manifest failed"
          else
            @task_status = :success
            puts "RexClient: set_manifest succeeded"
          end
          status = rex_send_status( @server, @sessionid, "#{status}" )
        else           
          status = rex_send_status( @server, @sessionid, :failure )
        end

      when :get_task_status
        # If the execution thread is running, we block until it is completed.
        if !@execthread.nil?
          @execthread.join
          @task_state = :completed
        end
        
        rex_send_status( @server, @sessionid, @task_status )

      when :exec_start
        puts "in case :exec_start"
        @task_status = :success
        @task_state = :running

        @execthread = Thread.new do
          @task_status = exec_resume(msg, 1)
        end


      when :exec_resume
        puts "in case :exec_resume"
        @task_status = :success
        @task_state = :running
        startstep = msg["startstep"]
        
        @execthread = Thread.new do
          @task_status = exec_resume( msg, startstep )
        end

      when :exec_kill
        puts "Received kill message, terminating client session"
        @task_state = :completed
        status = :success

      when :status_ack
        puts "in case :status_ack"
        raise "Invalid message for task client"

      else
        puts "Error, invalid message type"
        status = :failure

      end

      return status
    end

    def exec_resume( msg, startstep )

      actions = @manifest.manactions

      execstatus = 1
      retstatus = :success
      if startstep.to_i > actions.length.to_i
        puts "Error, startstep #{startstep} is out of bounds"
        return :failure
      end

      user = nil
      begin
        cmdenv = @manifest.manenv
        if cmdenv.has_key?("EXEC_USER")
          user = cmdenv["EXEC_USER"]
          prefix = "sudo su -l #{user} -c "
          #prefix = "sudo su -c "
        else
          prefix = ""
        end

        puts "Contents of command env follow:"
        #puts "cmdenv.inspect = #{cmdenv.inspect}"
        #puts "cmdenv.class = #{cmdenv.class}"
        pp cmdenv

        actions.each do |action|
          # Skip any prior steps to reach the startstep
          next if action.stepnum.to_i < startstep.to_i

          precommand = "#{action.command}"
          puts "precommand is \"#{precommand}\""

          exec_command = ""
          outstr, status = Open3.capture2e(cmdenv, "echo \"#{precommand}\"")
          exec_command = "#{prefix} \'#{outstr.chomp}\'"

          puts "Executing stepnum #{action.stepnum}: \"#{action.label}\""
          puts "command to be executed is \"#{exec_command}\""

          begin
            #pid = spawn(cmdenv, command)

            cmd_status = system(exec_command)
            puts "cmd_status = #{cmd_status}"
            procstatus = $?
            if cmd_status.nil?
              puts "Error, could not spawn command #{exec_command}"
              retstatus = :failure
            else
              execstatus = procstatus.exitstatus
              pid = procstatus.pid
              puts "execstatus = #{execstatus}, pid = #{pid}"
              if execstatus != 0
                puts "Error, failed to spawn command #{exec_command}"
                retstatus = :failure
              end
            end

            puts "Process #{pid}, step #{action.stepnum} completed with status #{execstatus}"
            action.exec_status = execstatus
          rescue => e
            puts "Encountered exception when spawning command, error follows:"
            pp e
            retstatus = :failure
          end

          if retstatus == :failure || "#{execstatus}" != "#{action.success_status}"
            retstatus = :failure
            break
          else
            retstatus = :success
          end
        end

      rescue => e
        pp e
        retstatus = :failure
      end

      puts "Returning from exec_resume"
      return retstatus

    end
  end

end
