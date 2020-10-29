# -*- encoding: binary -*-

# :enddoc:
# This code is based on the original CGIWrapper from Mongrel
# Copyright (c) 2005 Zed A. Shaw
# Copyright (c) 2009 Eric Wong
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
#
# Additional work donated by contributors.  See CONTRIBUTORS for more info.

require 'cgi'

module Unicorn; end

# The beginning of a complete wrapper around Unicorn's internal HTTP
# processing system but maintaining the original Ruby CGI module.  Use
# this only as a crutch to get existing CGI based systems working.  It
# should handle everything, but please notify us if you see special
# warnings.  This work is still very alpha so we need testers to help
# work out the various corner cases.
class Unicorn::CGIWrapper < ::CGI
  undef_method :env_table
  attr_reader :env_table
  attr_reader :body

  # these are stripped out of any keys passed to CGIWrapper.header function
  NPH = 'nph'.freeze # Completely ignored, Unicorn outputs the date regardless
  CONNECTION = 'connection'.freeze # Completely ignored. Why is CGI doing this?
  CHARSET = 'charset'.freeze # this gets appended to Content-Type
  COOKIE = 'cookie'.freeze # maps (Hash,Array,String) to "Set-Cookie" headers
  STATUS = 'status'.freeze # stored as @status
  Status = 'Status'.freeze # code + human-readable text, Rails sets this

  # some of these are common strings, but this is the only module
  # using them and the reason they're not in Unicorn::Const
  SET_COOKIE = 'Set-Cookie'.freeze
  CONTENT_TYPE = 'Content-Type'.freeze
  CONTENT_LENGTH = 'Content-Length'.freeze # this is NOT Const::CONTENT_LENGTH
  RACK_INPUT = 'rack.input'.freeze
  RACK_ERRORS = 'rack.errors'.freeze

  # this maps CGI header names to HTTP header names
  HEADER_MAP = {
    'status' => Status,
    'type' => CONTENT_TYPE,
    'server' => 'Server'.freeze,
    'language' => 'Content-Language'.freeze,
    'expires' => 'Expires'.freeze,
    'length' => CONTENT_LENGTH,
  }

  # Takes an a Rackable environment, plus any additional CGI.new
  # arguments These are used internally to create a wrapper around the
  # real CGI while maintaining Rack/Unicorn's view of the world.  This
  # this will NOT deal well with large responses that take up a lot of
  # memory, but neither does the CGI nor the original CGIWrapper from
  # Mongrel...
  def initialize(rack_env, *args)
    @env_table = rack_env
    @status = nil
    @head = {}
    @headv = Hash.new { |hash,key| hash[key] = [] }
    @body = StringIO.new("")
    super(*args)
  end

  # finalizes the response in a way Rack applications would expect
  def rack_response
    # @head[CONTENT_LENGTH] ||= @body.size
    @headv[SET_COOKIE].concat(@output_cookies) if @output_cookies
    @headv.each_pair do |key,value|
      @head[key] ||= value.join("\n") unless value.empty?
    end

    # Capitalized "Status:", with human-readable status code (e.g. "200 OK")
    @status ||= @head.delete(Status)

    [ @status || 500, @head, [ @body.string ] ]
  end

  # The header is typically called to send back the header.  In our case we
  # collect it into a hash for later usage.  This can be called multiple
  # times to set different cookies.
  def header(options = "text/html")
    # if they pass in a string then just write the Content-Type
    if String === options
      @head[CONTENT_TYPE] ||= options
    else
      HEADER_MAP.each_pair do |from, to|
        from = options.delete(from) or next
        @head[to] = from.to_s
      end

      @head[CONTENT_TYPE] ||= "text/html"
      if charset = options.delete(CHARSET)
        @head[CONTENT_TYPE] << "; charset=#{charset}"
      end

      # lots of ways to set cookies
      if cookie = options.delete(COOKIE)
        set_cookies = @headv[SET_COOKIE]
        case cookie
        when Array
          cookie.each { |c| set_cookies << c.to_s }
        when Hash
          cookie.each_value { |c| set_cookies << c.to_s }
        else
          set_cookies << cookie.to_s
        end
      end
      @status ||= options.delete(STATUS) # all lower-case

      # drop the keys we don't want anymore
      options.delete(NPH)
      options.delete(CONNECTION)

      # finally, set the rest of the headers as-is, allowing duplicates
      options.each_pair { |k,v| @headv[k] << v }
    end

    # doing this fakes out the cgi library to think the headers are empty
    # we then do the real headers in the out function call later
    ""
  end

  # The dumb thing is people can call header or this or both and in
  # any order.  So, we just reuse header and then finalize the
  # HttpResponse the right way.  This will have no effect if called
  # the second time if the first "outputted" anything.
  def out(options = "text/html")
    header(options)
    @body.size == 0 or return
    @body << yield if block_given?
  end

  # Used to wrap the normal stdinput variable used inside CGI.
  def stdinput
    @env_table[RACK_INPUT]
  end

  # return a pointer to the StringIO body since it's STDOUT-like
  def stdoutput
    @body
  end

end
