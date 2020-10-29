# -*- encoding: binary -*-

# :enddoc:
# This code is based on the original Rails handler in Mongrel
# Copyright (c) 2005 Zed A. Shaw
# Copyright (c) 2009 Eric Wong
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
# Additional work donated by contributors.  See CONTRIBUTORS for more info.
require 'unicorn/cgi_wrapper'
require 'dispatcher'

module Unicorn; module App; end; end

# Implements a handler that can run Rails.
class Unicorn::App::OldRails

  autoload :Static, "unicorn/app/old_rails/static"

  def call(env)
    cgi = Unicorn::CGIWrapper.new(env)
    begin
      Dispatcher.dispatch(cgi,
          ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS,
          cgi.body)
    rescue => e
      err = env['rack.errors']
      err.write("#{e} #{e.message}\n")
      e.backtrace.each { |line| err.write("#{line}\n") }
    end
    cgi.out  # finalize the response
    cgi.rack_response
  end

end
