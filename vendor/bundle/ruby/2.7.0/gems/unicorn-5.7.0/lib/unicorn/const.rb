# -*- encoding: binary -*-

module Unicorn::Const # :nodoc:
  # default TCP listen host address (0.0.0.0, all interfaces)
  DEFAULT_HOST = "0.0.0.0"

  # default TCP listen port (8080)
  DEFAULT_PORT = 8080

  # default TCP listen address and port (0.0.0.0:8080)
  DEFAULT_LISTEN = "#{DEFAULT_HOST}:#{DEFAULT_PORT}"

  # The basic request body size we'll try to read at once (16 kilobytes).
  CHUNK_SIZE = 16 * 1024

  # Maximum request body size before it is moved out of memory and into a
  # temporary file for reading (112 kilobytes).  This is the default
  # value of client_body_buffer_size.
  MAX_BODY = 1024 * 112
end
require_relative 'version'
