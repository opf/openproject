module OkComputer
  # Verifies if the mail server configured for ActionMailer is responding.
  class ActionMailerCheck < PingCheck

    attr_accessor :klass, :timeout, :host, :port

    def initialize(klass = ActionMailer::Base, timeout = 5)
      self.klass = klass
      self.timeout = timeout
      host = klass.smtp_settings[:address]
      port = klass.smtp_settings[:port] || 25
      super(host, port, timeout)
    end

    # Public: Return the status of the check
    def check
      tcp_socket_request
      mark_message "#{klass} check to #{host}:#{port} successful"
    rescue => e
      mark_message "#{klass} at #{host}:#{port} is not accepting connections: '#{e}'"
      mark_failure
    end
  end
end
