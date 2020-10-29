# frozen_string_literal: true

begin
  require 'io/wait'
rescue LoadError
end

# need for Puma::MiniSSL::OPENSSL constants used in `HAS_TLS1_3`
require 'puma/puma_http11'

module Puma
  module MiniSSL
    # Define constant at runtime, as it's easy to determine at built time,
    # but Puma could (it shouldn't) be loaded with an older OpenSSL version
    # @version 5.0.0
    HAS_TLS1_3 = !IS_JRUBY &&
      (OPENSSL_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) != -1 &&
      (OPENSSL_LIBRARY_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) !=-1

    class Socket
      def initialize(socket, engine)
        @socket = socket
        @engine = engine
        @peercert = nil
      end

      def to_io
        @socket
      end

      def closed?
        @socket.closed?
      end

      # Returns a two element array,
      # first is protocol version (SSL_get_version),
      # second is 'handshake' state (SSL_state_string)
      #
      # Used for dropping tcp connections to ssl.
      # See OpenSSL ssl/ssl_stat.c SSL_state_string for info
      # @version 5.0.0
      #
      def ssl_version_state
        IS_JRUBY ? [nil, nil] : @engine.ssl_vers_st
      end

      # Used to check the handshake status, in particular when a TCP connection
      # is made with TLSv1.3 as an available protocol
      # @version 5.0.0
      def bad_tlsv1_3?
        HAS_TLS1_3 && @engine.ssl_vers_st == ['TLSv1.3', 'SSLERR']
      end
      private :bad_tlsv1_3?

      def readpartial(size)
        while true
          output = @engine.read
          return output if output

          data = @socket.readpartial(size)
          @engine.inject(data)
          output = @engine.read

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def engine_read_all
        output = @engine.read
        raise SSLError.exception "HTTP connection?" if bad_tlsv1_3?
        while output and additional_output = @engine.read
          output << additional_output
        end
        output
      end

      def read_nonblock(size, *_)
        # *_ is to deal with keyword args that were added
        # at some point (and being used in the wild)
        while true
          output = engine_read_all
          return output if output

          data = @socket.read_nonblock(size, exception: false)
          if data == :wait_readable || data == :wait_writable
            # It would make more sense to let @socket.read_nonblock raise
            # EAGAIN if necessary but it seems like it'll misbehave on Windows.
            # I don't have a Windows machine to debug this so I can't explain
            # exactly whats happening in that OS. Please let me know if you
            # find out!
            #
            # In the meantime, we can emulate the correct behavior by
            # capturing :wait_readable & :wait_writable and raising EAGAIN
            # ourselves.
            raise IO::EAGAINWaitReadable
          elsif data.nil?
            return nil
          end

          @engine.inject(data)
          output = engine_read_all

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def write(data)
        return 0 if data.empty?

        need = data.bytesize

        while true
          wrote = @engine.write data
          enc = @engine.extract

          while enc
            @socket.write enc
            enc = @engine.extract
          end

          need -= wrote

          return data.bytesize if need == 0

          data = data[wrote..-1]
        end
      end

      alias_method :syswrite, :write
      alias_method :<<, :write

      # This is a temporary fix to deal with websockets code using
      # write_nonblock.

      # The problem with implementing it properly
      # is that it means we'd have to have the ability to rewind
      # an engine because after we write+extract, the socket
      # write_nonblock call might raise an exception and later
      # code would pass the same data in, but the engine would think
      # it had already written the data in.
      #
      # So for the time being (and since write blocking is quite rare),
      # go ahead and actually block in write_nonblock.
      #
      def write_nonblock(data, *_)
        write data
      end

      def flush
        @socket.flush
      end

      def read_and_drop(timeout = 1)
        return :timeout unless IO.select([@socket], nil, nil, timeout)
        case @socket.read_nonblock(1024, exception: false)
        when nil
          :eof
        when :wait_readable
          :eagain
        else
          :drop
        end
      end

      def should_drop_bytes?
        @engine.init? || !@engine.shutdown
      end

      def close
        begin
          # Read any drop any partially initialized sockets and any received bytes during shutdown.
          # Don't let this socket hold this loop forever.
          # If it can't send more packets within 1s, then give up.
          return if [:timeout, :eof].include?(read_and_drop(1)) while should_drop_bytes?
        rescue IOError, SystemCallError
          Thread.current.purge_interrupt_queue if Thread.current.respond_to? :purge_interrupt_queue
          # nothing
        ensure
          @socket.close
        end
      end

      def peeraddr
        @socket.peeraddr
      end

      def peercert
        return @peercert if @peercert

        raw = @engine.peercert
        return nil unless raw

        @peercert = OpenSSL::X509::Certificate.new raw
      end
    end

    if IS_JRUBY
      OPENSSL_NO_SSL3 = false
      OPENSSL_NO_TLS1 = false

      class SSLError < StandardError
        # Define this for jruby even though it isn't used.
      end
    end

    class Context
      attr_accessor :verify_mode
      attr_reader :no_tlsv1, :no_tlsv1_1

      def initialize
        @no_tlsv1   = false
        @no_tlsv1_1 = false
      end

      if IS_JRUBY
        # jruby-specific Context properties: java uses a keystore and password pair rather than a cert/key pair
        attr_reader :keystore
        attr_accessor :keystore_pass
        attr_accessor :ssl_cipher_list

        def keystore=(keystore)
          raise ArgumentError, "No such keystore file '#{keystore}'" unless File.exist? keystore
          @keystore = keystore
        end

        def check
          raise "Keystore not configured" unless @keystore
        end

      else
        # non-jruby Context properties
        attr_reader :key
        attr_reader :cert
        attr_reader :ca
        attr_accessor :ssl_cipher_filter

        def key=(key)
          raise ArgumentError, "No such key file '#{key}'" unless File.exist? key
          @key = key
        end

        def cert=(cert)
          raise ArgumentError, "No such cert file '#{cert}'" unless File.exist? cert
          @cert = cert
        end

        def ca=(ca)
          raise ArgumentError, "No such ca file '#{ca}'" unless File.exist? ca
          @ca = ca
        end

        def check
          raise "Key not configured" unless @key
          raise "Cert not configured" unless @cert
        end
      end

      # disables TLSv1
      def no_tlsv1=(tlsv1)
        raise ArgumentError, "Invalid value of no_tlsv1=" unless ['true', 'false', true, false].include?(tlsv1)
        @no_tlsv1 = tlsv1
      end

      # disables TLSv1 and TLSv1.1.  Overrides `#no_tlsv1=`
      def no_tlsv1_1=(tlsv1_1)
        raise ArgumentError, "Invalid value of no_tlsv1_1=" unless ['true', 'false', true, false].include?(tlsv1_1)
        @no_tlsv1_1 = tlsv1_1
      end

    end

    VERIFY_NONE = 0
    VERIFY_PEER = 1
    VERIFY_FAIL_IF_NO_PEER_CERT = 2

    class Server
      def initialize(socket, ctx)
        @socket = socket
        @ctx = ctx
      end

      def to_io
        @socket
      end

      def accept
        @ctx.check
        io = @socket.accept
        engine = Engine.server @ctx

        Socket.new io, engine
      end

      def accept_nonblock
        @ctx.check
        io = @socket.accept_nonblock
        engine = Engine.server @ctx

        Socket.new io, engine
      end

      # @version 5.0.0
      def addr
        @socket.addr
      end

      def close
        @socket.close unless @socket.closed?       # closed? call is for Windows
      end
    end
  end
end
