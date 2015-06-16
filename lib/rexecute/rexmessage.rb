# This module defines REX message types, encoding, and decoding.
#
# July 2014 Bob Ashforth, RelEng
#

require 'json'
require 'pp'
require 'logger'

class RexMessage

  # We put these symbols into an array so that we can check for validity
  # of each message type we encounter
  REX_MESSAGE_TYPES = [ :rex_init, :set_manifest, :get_task_state,
    :get_task_status, :status_ack, :exec_start, :exec_resume, :exec_kill ]

  REX_MESSAGE_RETURNS = [ :success, :failure, :invalid_message_type ]

  REX_TASK_STATES = [ :init, :idle, :running, :succeeded, :failed, :killed, :paused ]

  def initialize
    # This class is meant to be completely abstract; descendant classes will
    # initialize the logger as appropriate.
    @logger = nil
    @command_mutex = nil
  end

  def check( status )
    raise if "#{status}" == "status"
  end

  def rex_send_command( sock, conversationid, message_type, payload=nil )
    # This method is a paper-thin wrapper around rex_send_message, used only to distinguish
    # messages which are API commands from other commands. This permits use of a mutex to
    # serialize commands, without interfering with message sending within the implementation
    # of the API commands.
    status = rex_send_message( sock, conversationid, message_type, payload )
    check( status )
    return status
  end

  def rex_send_message( sock, conversationid, message_type, payload=nil )
    
    @logger.info("In rex_send_message")
    msg = rex_wrap_message( conversationid, message_type, payload )
    if msg.nil?
      @logger.fatal( "Error, failed to wrap message." )
    end
    @logger.info("rex_send_message, msg=#{msg}")
    
    status = rex_send_raw( sock, msg )
    check( status )

    if status != :success
      @logger.error( "rex_send_message failed, mtype=\"#{message_type}\", status=\"status\"" )
    end

    return status
  end

  def rex_send_raw( sock, rex_message )

    status = :success
    begin
      sock.puts( rex_message )
      #@logger.info( rex_message )
      @logger.info("rex_send_raw: message sent, #{rex_message}")
    rescue => e
      pp e
      @logger.error( "Error in sending message using socket" )
      @logger.error( e )
      status = :failure
    end

    return status
  end

  def rex_send_status( sock, conversationid, status )
    @logger.info("In rex_send_status, status is #{status}")

    payload = Hash.new
    payload["status"] = "#{status}"
    status = rex_send_message( sock, conversationid, :status_ack, payload )

    return status
  end

  # Each message object is an array of hashes; the value of any given hash
  # can be a ruby object of arbitrary complexity.
  # (No 'unwrap' method is provided because json.parse() suffices.)
  def rex_wrap_message( sessionid, message_type, payload=nil )

    @logger.info(message_type)

    if sessionid.empty? or message_type.empty?
      @logger.error( "Error, message_type and sessionid must be provided" )
      return nil
    end

    if not REX_MESSAGE_TYPES.include?( message_type )
      @logger.error( "Error, invalid message type #{message_type}" )
      return nil
    end

    msg = Hash.new
    msg["sessionid"] = "#{sessionid}"
    msg["message_type"] = "#{message_type}"

    if payload.nil?
      jmsg = msg.to_json
      logger.info("rexmessage, jmsg = #{jmsg}")
    else
      jmsg = msg.merge( payload ).to_json
    end

    @logger.info("jmsg: #{jmsg}")
    return jmsg

  end

  def rex_get_message( sock )
    msg = rex_get_message_raw( sock )
    #@logger.info "rex_get_message, msg=\"#{msg}\"")

    return JSON.parse( msg )
  end

  def rex_get_message_raw( sock )

    begin
      #pp sock
      #pp sid
      @logger.info( "In rex_get_message_raw, sock=#{sock}" )

      msg = sock.gets
      if !msg.nil?
        msg = msg.chomp
        #@logger.info(msg)
      else
        @logger.info("rex_get_message_raw: received nil message")
      end

    rescue => e
      @logger.error( "Error in getting message" )
      @logger.error( e.message )
      @logger.error( e.backtrace )
    end

    return msg
  end

  def reap_task( sock, conversationid )

    rex_send_message( sock, conversationid, :reap_task )

    status = read_task_status( sock, conversationid )
    @logger.info("In get_task_status, status is #{status}")
    return status
  end

  def get_task_status( sock, conversationid )

    rex_send_message( sock, conversationid, :get_task_status )

    status = read_task_status( sock, conversationid )
    @logger.info("In get_task_status, status is #{status}")
    return status
  end

  def read_task_status( sock, conversationid )
    msg = rex_get_message( sock )
    mtype = msg["message_type"].to_sym
    status = :success

    if mtype == :status_ack
      status = msg["status"].to_sym
      @logger.info("Setting status to #{status}.to_sym")
    else
      status = :invalid_message_type
      @logger.error( "Invalid message type #{mtype}, status set to #{status}")
    end

    @logger.info("In read_task_status, status is #{status}")

    return status

  end

end
