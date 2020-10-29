# -*- encoding: binary -*-
require 'socket'

# See the {README}[link:index.html]
module Kgio

  # The IPv4 address of UNIX domain sockets, useful for creating
  # Rack (and CGI) servers that also serve HTTP traffic over
  # UNIX domain sockets.
  LOCALHOST = '127.0.0.1'

  # Kgio::PipeMethods#kgio_tryread and Kgio::SocketMethods#kgio_tryread will
  # return :wait_readable when waiting for a read is required.
  WaitReadable = :wait_readable

  # PipeMethods#kgio_trywrite and SocketMethods#kgio_trywrite will return
  # :wait_writable when waiting for a read is required.
  WaitWritable = :wait_writable
end

require 'kgio_ext'

# use Kgio::Pipe.popen and Kgio::Pipe.new instead of IO.popen
# and IO.pipe to get PipeMethods#kgio_read and PipeMethod#kgio_write
# methods.
class Kgio::Pipe < IO
  include Kgio::PipeMethods
  class << self

    # call-seq:
    #
    #   rd, wr = Kgio::Pipe.new
    #
    # This creates a new pipe(7) with Kgio::Pipe objects that respond
    # to PipeMethods#kgio_read and PipeMethod#kgio_write
    alias new pipe
  end
end
