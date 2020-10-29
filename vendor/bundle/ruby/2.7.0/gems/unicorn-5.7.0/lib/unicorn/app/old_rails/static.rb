# -*- encoding: binary -*-
# :enddoc:
# This code is based on the original Rails handler in Mongrel
# Copyright (c) 2005 Zed A. Shaw
# Copyright (c) 2009 Eric Wong
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv3

# Static file handler for Rails < 2.3.  This handler is only provided
# as a convenience for developers.  Performance-minded deployments should
# use nginx (or similar) for serving static files.
#
# This supports page caching directly and will try to resolve a
# request in the following order:
#
# * If the requested exact PATH_INFO exists as a file then serve it.
# * If it exists at PATH_INFO+rest_operator+".html" exists
#   then serve that.
#
# This means that if you are using page caching it will actually work
# with Unicorn and you should see a decent speed boost (but not as
# fast as if you use a static server like nginx).
class Unicorn::App::OldRails::Static < Struct.new(:app, :root, :file_server)
  FILE_METHODS = { 'GET' => true, 'HEAD' => true }

  # avoid allocating new strings for hash lookups
  REQUEST_METHOD = 'REQUEST_METHOD'
  REQUEST_URI = 'REQUEST_URI'
  PATH_INFO = 'PATH_INFO'

  def initialize(app)
    self.app = app
    self.root = "#{::RAILS_ROOT}/public"
    self.file_server = ::Rack::File.new(root)
  end

  def call(env)
    # short circuit this ASAP if serving non-file methods
    FILE_METHODS.include?(env[REQUEST_METHOD]) or return app.call(env)

    # first try the path as-is
    path_info = env[PATH_INFO].chomp("/")
    if File.file?("#{root}/#{::Rack::Utils.unescape(path_info)}")
      # File exists as-is so serve it up
      env[PATH_INFO] = path_info
      return file_server.call(env)
    end

    # then try the cached version:
    path_info << ActionController::Base.page_cache_extension

    if File.file?("#{root}/#{::Rack::Utils.unescape(path_info)}")
      env[PATH_INFO] = path_info
      return file_server.call(env)
    end

    app.call(env) # call OldRails
  end
end if defined?(Unicorn::App::OldRails)
