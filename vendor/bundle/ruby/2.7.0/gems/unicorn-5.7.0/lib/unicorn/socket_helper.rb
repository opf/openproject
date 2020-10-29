# -*- encoding: binary -*-
# :enddoc:
require 'socket'

module Unicorn

  # Instead of using a generic Kgio::Socket for everything,
  # tag TCP sockets so we can use TCP_INFO under Linux without
  # incurring extra syscalls for Unix domain sockets.
  # TODO: remove these when we remove kgio
  TCPClient = Class.new(Kgio::Socket) # :nodoc:
  class TCPSrv < Kgio::TCPServer # :nodoc:
    def kgio_tryaccept # :nodoc:
      super(TCPClient)
    end
  end

  module SocketHelper

    # internal interface
    DEFAULTS = {
      # The semantics for TCP_DEFER_ACCEPT changed in Linux 2.6.32+
      # with commit d1b99ba41d6c5aa1ed2fc634323449dd656899e9
      # This change shouldn't affect unicorn users behind nginx (a
      # value of 1 remains an optimization).
      :tcp_defer_accept => 1,

      # FreeBSD, we need to override this to 'dataready' if we
      # eventually support non-HTTP/1.x
      :accept_filter => 'httpready',

      # same default value as Mongrel
      :backlog => 1024,

      # favor latency over bandwidth savings
      :tcp_nopush => nil,
      :tcp_nodelay => true,
    }

    # configure platform-specific options (only tested on Linux 2.6 so far)
    def accf_arg(af_name)
      [ af_name, nil ].pack('a16a240')
    end if RUBY_PLATFORM =~ /freebsd/ && Socket.const_defined?(:SO_ACCEPTFILTER)

    def set_tcp_sockopt(sock, opt)
      # just in case, even LANs can break sometimes.  Linux sysadmins
      # can lower net.ipv4.tcp_keepalive_* sysctl knobs to very low values.
      Socket.const_defined?(:SO_KEEPALIVE) and
        sock.setsockopt(:SOL_SOCKET, :SO_KEEPALIVE, 1)

      if Socket.const_defined?(:TCP_NODELAY)
        val = opt[:tcp_nodelay]
        val = DEFAULTS[:tcp_nodelay] if val.nil?
        sock.setsockopt(:IPPROTO_TCP, :TCP_NODELAY, val ? 1 : 0)
      end

      val = opt[:tcp_nopush]
      unless val.nil?
        if Socket.const_defined?(:TCP_CORK) # Linux
          sock.setsockopt(:IPPROTO_TCP, :TCP_CORK, val)
        elsif Socket.const_defined?(:TCP_NOPUSH) # FreeBSD
          sock.setsockopt(:IPPROTO_TCP, :TCP_NOPUSH, val)
        end
      end

      # No good reason to ever have deferred accepts off in single-threaded
      # servers (except maybe benchmarking)
      if Socket.const_defined?(:TCP_DEFER_ACCEPT)
        # this differs from nginx, since nginx doesn't allow us to
        # configure the the timeout...
        seconds = opt[:tcp_defer_accept]
        seconds = DEFAULTS[:tcp_defer_accept] if [true,nil].include?(seconds)
        seconds = 0 unless seconds # nil/false means disable this
        sock.setsockopt(:IPPROTO_TCP, :TCP_DEFER_ACCEPT, seconds)
      elsif respond_to?(:accf_arg)
        name = opt[:accept_filter]
        name = DEFAULTS[:accept_filter] if name.nil?
        sock.listen(opt[:backlog])
        got = (sock.getsockopt(:SOL_SOCKET, :SO_ACCEPTFILTER) rescue nil).to_s
        arg = accf_arg(name)
        begin
          sock.setsockopt(:SOL_SOCKET, :SO_ACCEPTFILTER, arg)
        rescue => e
          logger.error("#{sock_name(sock)} " \
                       "failed to set accept_filter=#{name} (#{e.inspect})")
          logger.error("perhaps accf_http(9) needs to be loaded".freeze)
        end if arg != got
      end
    end

    def set_server_sockopt(sock, opt)
      opt = DEFAULTS.merge(opt || {})

      TCPSocket === sock and set_tcp_sockopt(sock, opt)

      rcvbuf, sndbuf = opt.values_at(:rcvbuf, :sndbuf)
      if rcvbuf || sndbuf
        log_buffer_sizes(sock, "before: ")
        sock.setsockopt(:SOL_SOCKET, :SO_RCVBUF, rcvbuf) if rcvbuf
        sock.setsockopt(:SOL_SOCKET, :SO_SNDBUF, sndbuf) if sndbuf
        log_buffer_sizes(sock, " after: ")
      end
      sock.listen(opt[:backlog])
    rescue => e
      Unicorn.log_error(logger, "#{sock_name(sock)} #{opt.inspect}", e)
    end

    def log_buffer_sizes(sock, pfx = '')
      rcvbuf = sock.getsockopt(:SOL_SOCKET, :SO_RCVBUF).int
      sndbuf = sock.getsockopt(:SOL_SOCKET, :SO_SNDBUF).int
      logger.info "#{pfx}#{sock_name(sock)} rcvbuf=#{rcvbuf} sndbuf=#{sndbuf}"
    end

    # creates a new server, socket. address may be a HOST:PORT or
    # an absolute path to a UNIX socket.  address can even be a Socket
    # object in which case it is immediately returned
    def bind_listen(address = '0.0.0.0:8080', opt = {})
      return address unless String === address

      sock = if address.start_with?('/')
        if File.exist?(address)
          if File.socket?(address)
            begin
              UNIXSocket.new(address).close
              # fall through, try to bind(2) and fail with EADDRINUSE
              # (or succeed from a small race condition we can't sanely avoid).
            rescue Errno::ECONNREFUSED
              logger.info "unlinking existing socket=#{address}"
              File.unlink(address)
            end
          else
            raise ArgumentError,
                  "socket=#{address} specified but it is not a socket!"
          end
        end
        old_umask = File.umask(opt[:umask] || 0)
        begin
          Kgio::UNIXServer.new(address)
        ensure
          File.umask(old_umask)
        end
      elsif /\A\[([a-fA-F0-9:]+)\]:(\d+)\z/ =~ address
        new_tcp_server($1, $2.to_i, opt.merge(:ipv6=>true))
      elsif /\A(\d+\.\d+\.\d+\.\d+):(\d+)\z/ =~ address
        new_tcp_server($1, $2.to_i, opt)
      else
        raise ArgumentError, "Don't know how to bind: #{address}"
      end
      set_server_sockopt(sock, opt)
      sock
    end

    def new_tcp_server(addr, port, opt)
      # n.b. we set FD_CLOEXEC in the workers
      sock = Socket.new(opt[:ipv6] ? :AF_INET6 : :AF_INET, :SOCK_STREAM)
      if opt.key?(:ipv6only)
        Socket.const_defined?(:IPV6_V6ONLY) or
          abort "Socket::IPV6_V6ONLY not defined, upgrade Ruby and/or your OS"
        sock.setsockopt(:IPPROTO_IPV6, :IPV6_V6ONLY, opt[:ipv6only] ? 1 : 0)
      end
      sock.setsockopt(:SOL_SOCKET, :SO_REUSEADDR, 1)
      if Socket.const_defined?(:SO_REUSEPORT) && opt[:reuseport]
        sock.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
      end
      sock.bind(Socket.pack_sockaddr_in(port, addr))
      sock.autoclose = false
      TCPSrv.for_fd(sock.fileno)
    end

    # returns rfc2732-style (e.g. "[::1]:666") addresses for IPv6
    def tcp_name(sock)
      port, addr = Socket.unpack_sockaddr_in(sock.getsockname)
      addr.include?(':') ? "[#{addr}]:#{port}" : "#{addr}:#{port}"
    end
    module_function :tcp_name

    # Returns the configuration name of a socket as a string.  sock may
    # be a string value, in which case it is returned as-is
    # Warning: TCP sockets may not always return the name given to it.
    def sock_name(sock)
      case sock
      when String then sock
      when UNIXServer
        Socket.unpack_sockaddr_un(sock.getsockname)
      when TCPServer
        tcp_name(sock)
      when Socket
        begin
          tcp_name(sock)
        rescue ArgumentError
          Socket.unpack_sockaddr_un(sock.getsockname)
        end
      else
        raise ArgumentError, "Unhandled class #{sock.class}: #{sock.inspect}"
      end
    end

    module_function :sock_name

    # casts a given Socket to be a TCPServer or UNIXServer
    def server_cast(sock)
      begin
        Socket.unpack_sockaddr_in(sock.getsockname)
        TCPSrv.for_fd(sock.fileno)
      rescue ArgumentError
        Kgio::UNIXServer.for_fd(sock.fileno)
      end
    end

  end # module SocketHelper
end # module Unicorn
