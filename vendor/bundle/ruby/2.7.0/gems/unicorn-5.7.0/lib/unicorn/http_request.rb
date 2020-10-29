# -*- encoding: binary -*-
# :enddoc:
# no stable API here
require 'unicorn_http'

# TODO: remove redundant names
Unicorn.const_set(:HttpRequest, Unicorn::HttpParser)
class Unicorn::HttpParser

  # default parameters we merge into the request env for Rack handlers
  DEFAULTS = {
    "rack.errors" => $stderr,
    "rack.multiprocess" => true,
    "rack.multithread" => false,
    "rack.run_once" => false,
    "rack.version" => [1, 2],
    "rack.hijack?" => true,
    "SCRIPT_NAME" => "",

    # this is not in the Rack spec, but some apps may rely on it
    "SERVER_SOFTWARE" => "Unicorn #{Unicorn::Const::UNICORN_VERSION}"
  }

  NULL_IO = StringIO.new("")

  # :stopdoc:
  HTTP_RESPONSE_START = [ 'HTTP'.freeze, '/1.1 '.freeze ]
  EMPTY_ARRAY = [].freeze
  @@input_class = Unicorn::TeeInput
  @@check_client_connection = false
  @@tcpi_inspect_ok = Socket.const_defined?(:TCP_INFO)

  def self.input_class
    @@input_class
  end

  def self.input_class=(klass)
    @@input_class = klass
  end

  def self.check_client_connection
    @@check_client_connection
  end

  def self.check_client_connection=(bool)
    @@check_client_connection = bool
  end

  # :startdoc:

  # Does the majority of the IO processing.  It has been written in
  # Ruby using about 8 different IO processing strategies.
  #
  # It is currently carefully constructed to make sure that it gets
  # the best possible performance for the common case: GET requests
  # that are fully complete after a single read(2)
  #
  # Anyone who thinks they can make it faster is more than welcome to
  # take a crack at it.
  #
  # returns an environment hash suitable for Rack if successful
  # This does minimal exception trapping and it is up to the caller
  # to handle any socket errors (e.g. user aborted upload).
  def read(socket)
    clear
    e = env

    # From https://www.ietf.org/rfc/rfc3875:
    # "Script authors should be aware that the REMOTE_ADDR and
    #  REMOTE_HOST meta-variables (see sections 4.1.8 and 4.1.9)
    #  may not identify the ultimate source of the request.  They
    #  identify the client for the immediate request to the server;
    #  that client may be a proxy, gateway, or other intermediary
    #  acting on behalf of the actual source client."
    e['REMOTE_ADDR'] = socket.kgio_addr

    # short circuit the common case with small GET requests first
    socket.kgio_read!(16384, buf)
    if parse.nil?
      # Parser is not done, queue up more data to read and continue parsing
      # an Exception thrown from the parser will throw us out of the loop
      false until add_parse(socket.kgio_read!(16384))
    end

    check_client_connection(socket) if @@check_client_connection

    e['rack.input'] = 0 == content_length ?
                      NULL_IO : @@input_class.new(socket, self)

    # for Rack hijacking in Rack 1.5 and later
    e['unicorn.socket'] = socket
    e['rack.hijack'] = self

    e.merge!(DEFAULTS)
  end

  # for rack.hijack, we respond to this method so no extra allocation
  # of a proc object
  def call
    hijacked!
    env['rack.hijack_io'] = env['unicorn.socket']
  end

  def hijacked?
    env.include?('rack.hijack_io'.freeze)
  end

  if Raindrops.const_defined?(:TCP_Info)
    TCPI = Raindrops::TCP_Info.allocate

    def check_client_connection(socket) # :nodoc:
      if Unicorn::TCPClient === socket
        # Raindrops::TCP_Info#get!, #state (reads struct tcp_info#tcpi_state)
        raise Errno::EPIPE, "client closed connection".freeze,
              EMPTY_ARRAY if closed_state?(TCPI.get!(socket).state)
      else
        write_http_header(socket)
      end
    end

    if Raindrops.const_defined?(:TCP)
      # raindrops 0.18.0+ supports FreeBSD + Linux using the same names
      # Evaluate these hash lookups at load time so we can
      # generate an opt_case_dispatch instruction
      eval <<-EOS
      def closed_state?(state) # :nodoc:
        case state
        when #{Raindrops::TCP[:ESTABLISHED]}
          false
        when #{Raindrops::TCP.values_at(
              :CLOSE_WAIT, :TIME_WAIT, :CLOSE, :LAST_ACK, :CLOSING).join(',')}
          true
        else
          false
        end
      end
      EOS
    else
      # raindrops before 0.18 only supported TCP_INFO under Linux
      def closed_state?(state) # :nodoc:
        case state
        when 1 # ESTABLISHED
          false
        when 8, 6, 7, 9, 11 # CLOSE_WAIT, TIME_WAIT, CLOSE, LAST_ACK, CLOSING
          true
        else
          false
        end
      end
    end
  else

    # Ruby 2.2+ can show struct tcp_info as a string Socket::Option#inspect.
    # Not that efficient, but probably still better than doing unnecessary
    # work after a client gives up.
    def check_client_connection(socket) # :nodoc:
      if Unicorn::TCPClient === socket && @@tcpi_inspect_ok
        opt = socket.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO).inspect
        if opt =~ /\bstate=(\S+)/
          raise Errno::EPIPE, "client closed connection".freeze,
                EMPTY_ARRAY if closed_state_str?($1)
        else
          @@tcpi_inspect_ok = false
          write_http_header(socket)
        end
        opt.clear
      else
        write_http_header(socket)
      end
    end

    def closed_state_str?(state)
      case state
      when 'ESTABLISHED'
        false
      # not a typo, ruby maps TCP_CLOSE (no 'D') to state=CLOSED (w/ 'D')
      when 'CLOSE_WAIT', 'TIME_WAIT', 'CLOSED', 'LAST_ACK', 'CLOSING'
        true
      else
        false
      end
    end
  end

  def write_http_header(socket) # :nodoc:
    if headers?
      self.response_start_sent = true
      HTTP_RESPONSE_START.each { |c| socket.write(c) }
    end
  end

  # called by ext/unicorn_http/unicorn_http.rl via rb_funcall
  def self.is_chunked?(v) # :nodoc:
    vals = v.split(/[ \t]*,[ \t]*/).map!(&:downcase)
    if vals.pop == 'chunked'.freeze
      return true unless vals.include?('chunked'.freeze)
      raise Unicorn::HttpParserError, 'double chunked', []
    end
    return false unless vals.include?('chunked'.freeze)
    raise Unicorn::HttpParserError, 'chunked not last', []
  end
end
