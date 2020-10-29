module OkComputer
  # Performs a health check by making a TCPSocket request to the host and port.
  # A non-error response is considered passing.
  class PingCheck < Check
    ConnectionFailed = Class.new(StandardError)

    attr_accessor :host, :port, :request_timeout

    # Public: Initialize a new ping check.
    #
    # host - the hostname
    # port - the port, as a string
    # request_timeout - How long to wait to connect before timing out. Defaults to 5 seconds.
    def initialize(host, port, request_timeout = 5)
      raise ArgumentError if host.blank? || port.blank?
      self.host = host
      self.port = port
      self.request_timeout = request_timeout.to_i
    end

    # Public: Return the status of the Ping check
    def check
      tcp_socket_request
      mark_message "Ping check to #{host}:#{port} successful"
    rescue => e
      mark_message "Error: '#{e}'"
      mark_failure
    end

    private

    # Returns true if the request was successful.
    # Otherwise raises a PingCheck::ConnectionFailed error.
    def tcp_socket_request
      Timeout.timeout(request_timeout) do
        s = TCPSocket.new(host, port)
        s.close
      end
    rescue Errno::ECONNREFUSED => e
      addl_message = "#{host} is not accepting connections on port #{port}: "
      raise ConnectionFailed, addl_message + e.message
    rescue SocketError => e
      addl_message = "connection to #{host} on port #{port} failed with '#{e.message}': "
      raise ConnectionFailed, addl_message + e.message
    rescue Timeout::Error => e
      addl_message = "#{host} did not respond on port #{port} within #{request_timeout} seconds: "
      raise ConnectionFailed, addl_message + e.message
    rescue => e
      raise ConnectionFailed, e
    end
  end
end
