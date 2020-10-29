# -*- encoding: binary -*-

# Acts like tee(1) on an input input to provide a input-like stream
# while providing rewindable semantics through a File/StringIO backing
# store.  On the first pass, the input is only read on demand so your
# Rack application can use input notification (upload progress and
# like).  This should fully conform to the Rack::Lint::InputWrapper
# specification on the public API.  This class is intended to be a
# strict interpretation of Rack::Lint::InputWrapper functionality and
# will not support any deviations from it.
#
# When processing uploads, unicorn exposes a TeeInput object under
# "rack.input" of the Rack environment by default.
class Unicorn::TeeInput < Unicorn::StreamInput
  # The maximum size (in +bytes+) to buffer in memory before
  # resorting to a temporary file.  Default is 112 kilobytes.
  @@client_body_buffer_size = Unicorn::Const::MAX_BODY # :nodoc:

  # sets the maximum size of request bodies to buffer in memory,
  # amounts larger than this are buffered to the filesystem
  def self.client_body_buffer_size=(bytes) # :nodoc:
    @@client_body_buffer_size = bytes
  end

  # returns the maximum size of request bodies to buffer in memory,
  # amounts larger than this are buffered to the filesystem
  def self.client_body_buffer_size # :nodoc:
    @@client_body_buffer_size
  end

  # for Rack::TempfileReaper in rack 1.6+
  def new_tmpio # :nodoc:
    tmpio = Unicorn::TmpIO.new
    (@parser.env['rack.tempfiles'] ||= []) << tmpio
    tmpio
  end

  # Initializes a new TeeInput object.  You normally do not have to call
  # this unless you are writing an HTTP server.
  def initialize(socket, request) # :nodoc:
    @len = request.content_length
    super
    @tmp = @len && @len <= @@client_body_buffer_size ?
           StringIO.new("") : new_tmpio
  end

  # :call-seq:
  #   ios.size  => Integer
  #
  # Returns the size of the input.  For requests with a Content-Length
  # header value, this will not read data off the socket and just return
  # the value of the Content-Length header as an Integer.
  #
  # For Transfer-Encoding:chunked requests, this requires consuming
  # all of the input stream before returning since there's no other
  # way to determine the size of the request body beforehand.
  #
  # This method is no longer part of the Rack specification as of
  # Rack 1.2, so its use is not recommended.  This method only exists
  # for compatibility with Rack applications designed for Rack 1.1 and
  # earlier.  Most applications should only need to call +read+ with a
  # specified +length+ in a loop until it returns +nil+.
  def size
    @len and return @len
    pos = @tmp.pos
    consume!
    @tmp.pos = pos
    @len = @tmp.size
  end

  # :call-seq:
  #   ios.read([length [, buffer ]]) => string, buffer, or nil
  #
  # Reads at most length bytes from the I/O stream, or to the end of
  # file if length is omitted or is nil. length must be a non-negative
  # integer or nil. If the optional buffer argument is present, it
  # must reference a String, which will receive the data.
  #
  # At end of file, it returns nil or "" depend on length.
  # ios.read() and ios.read(nil) returns "".
  # ios.read(length [, buffer]) returns nil.
  #
  # If the Content-Length of the HTTP request is known (as is the common
  # case for POST requests), then ios.read(length [, buffer]) will block
  # until the specified length is read (or it is the last chunk).
  # Otherwise, for uncommon "Transfer-Encoding: chunked" requests,
  # ios.read(length [, buffer]) will return immediately if there is
  # any data and only block when nothing is available (providing
  # IO#readpartial semantics).
  def read(*args)
    @socket ? tee(super) : @tmp.read(*args)
  end

  # :call-seq:
  #   ios.gets   => string or nil
  #
  # Reads the next ``line'' from the I/O stream; lines are separated
  # by the global record separator ($/, typically "\n"). A global
  # record separator of nil reads the entire unread contents of ios.
  # Returns nil if called at the end of file.
  # This takes zero arguments for strict Rack::Lint compatibility,
  # unlike IO#gets.
  def gets
    @socket ? tee(super) : @tmp.gets
  end

  # :call-seq:
  #   ios.rewind    => 0
  #
  # Positions the *ios* pointer to the beginning of input, returns
  # the offset (zero) of the +ios+ pointer.  Subsequent reads will
  # start from the beginning of the previously-buffered input.
  def rewind
    return 0 if 0 == @tmp.size
    consume! if @socket
    @tmp.rewind # Rack does not specify what the return value is here
  end

private

  # consumes the stream of the socket
  def consume!
    junk = ""
    nil while read(@@io_chunk_size, junk)
  end

  def tee(buffer)
    @tmp.write(buffer) if buffer
    buffer
  end
end
