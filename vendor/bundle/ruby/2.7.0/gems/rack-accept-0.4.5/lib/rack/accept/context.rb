module Rack::Accept
  # Implements the Rack middleware interface.
  class Context
    # This error is raised when the server is not able to provide an acceptable
    # response.
    class AcceptError < StandardError; end

    attr_reader :app

    def initialize(app)
      @app = app
      @checks = {}
      @check_headers = []
      yield self if block_given?
    end

    # Inserts a new Rack::Accept::Request object into the environment before
    # handing the request to the app immediately downstream.
    def call(env)
      request = env['rack-accept.request'] ||= Request.new(env)
      check!(request) unless @checks.empty?
      @app.call(env)
    rescue AcceptError
      response = Response.new
      response.not_acceptable!
      response.finish
    end

    # Defines the types of media this server is able to serve.
    def media_types=(media_types)
      add_check(:media_type, media_types)
    end

    # Defines the character sets this server is able to serve.
    def charsets=(charsets)
      add_check(:charset, charsets)
    end

    # Defines the types of encodings this server is able to serve.
    def encodings=(encodings)
      add_check(:encoding, encodings)
    end

    # Defines the languages this server is able to serve.
    def languages=(languages)
      add_check(:language, languages)
    end

  private

    def add_check(header_name, values)
      @checks[header_name] ||= []
      @checks[header_name].concat(values)
      @check_headers << header_name unless @check_headers.include?(header_name)
    end

    # Raises an AcceptError if this server is not able to serve an acceptable
    # response.
    def check!(request)
      @check_headers.each do |header_name|
        values = @checks[header_name]
        header = request.send(header_name)
        raise AcceptError unless values.any? {|v| header.accept?(v) }
      end
    end
  end
end
