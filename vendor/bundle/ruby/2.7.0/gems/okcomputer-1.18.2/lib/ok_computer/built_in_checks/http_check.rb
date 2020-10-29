require "open-uri"

module OkComputer
  # Performs a health check by reading a URL over HTTP.
  # A successful response is considered passing.
  # To implement your own pass/fail criteria, inherit from this
  # class, override #check, and call #perform_request to get the
  # response body.
  class HttpCheck < Check
    ConnectionFailed = Class.new(StandardError)

    attr_accessor :url, :request_timeout, :basic_auth_username, :basic_auth_password

    # Public: Initialize a new HTTP check.
    #
    # url - The URL to check
    # request_timeout - How long to wait to connect before timing out. Defaults to 5 seconds.
    def initialize(url, request_timeout = 5)
      parse_url(url)
      self.request_timeout = request_timeout.to_i
    end

    # Public: Return the status of the HTTP check
    def check
      if perform_request
        mark_message "HTTP check successful"
      end
    rescue => e
      mark_message "Error: '#{e}'"
      mark_failure
    end

    # Public: Actually performs the request against the URL.
    # Returns response body if the request was successful.
    # Otherwise raises a HttpCheck::ConnectionFailed error.
    def perform_request
      Timeout.timeout(request_timeout) do
        options = { read_timeout: request_timeout }

        if basic_auth_options.any?
          options[:http_basic_authentication] = basic_auth_options
        end

        url.read(options)
      end
    rescue => e
      raise ConnectionFailed, e
    end

    def parse_url(url)
      self.url = URI.parse(url)
      if self.url.userinfo
        self.basic_auth_username, self.basic_auth_password = self.url.userinfo.split(':')
        self.url.userinfo = ''
      end
    end

    def basic_auth_options
      [self.basic_auth_username, self.basic_auth_password]
    end
  end
end
