# -*- encoding: binary -*-

# When processing uploads, unicorn may expose a StreamInput object under
# "rack.input" of the Rack environment when
# Unicorn::Configurator#rewindable_input is set to +false+
class Unicorn::StreamInput
  # The I/O chunk size (in +bytes+) for I/O operations where
  # the size cannot be user-specified when a method is called.
  # The default is 16 kilobytes.
  @@io_chunk_size = Unicorn::Const::CHUNK_SIZE # :nodoc:

  # Initializes a new StreamInput object.  You normally do not have to call
  # this unless you are writing an HTTP server.
  def initialize(socket, request) # :nodoc:
    @chunked = request.content_length.nil?
    @socket = socket
    @parser = request
    @buf = request.buf
    @rbuf = ''
    @bytes_read = 0
    filter_body(@rbuf, @buf) unless @buf.empty?
  end

  # :call-seq:
  #   ios.read([length [, buffer ]]) => string, buffer, or nil
  #
  # Reads at most length bytes from the I/O stream, or to the end of
  # file if length is omitted or is nil. length must be a non-negative
  # integer or nil. If the optional buffer argument is present, it
  # must reference a String, which will receive the data.
  #
  # At end of file, it returns nil or '' depend on length.
  # ios.read() and ios.read(nil) returns ''.
  # ios.read(length [, buffer]) returns nil.
  #
  # If the Content-Length of the HTTP request is known (as is the common
  # case for POST requests), then ios.read(length [, buffer]) will block
  # until the specified length is read (or it is the last chunk).
  # Otherwise, for uncommon "Transfer-Encoding: chunked" requests,
  # ios.read(length [, buffer]) will return immediately if there is
  # any data and only block when nothing is available (providing
  # IO#readpartial semantics).
  def read(length = nil, rv = '')
    if length
      if length <= @rbuf.size
        length < 0 and raise ArgumentError, "negative length #{length} given"
        rv.replace(@rbuf.slice!(0, length))
      else
        to_read = length - @rbuf.size
        rv.replace(@rbuf.slice!(0, @rbuf.size))
        until to_read == 0 || eof? || (rv.size > 0 && @chunked)
          @socket.kgio_read(to_read, @buf) or eof!
          filter_body(@rbuf, @buf)
          rv << @rbuf
          to_read -= @rbuf.size
        end
        @rbuf.clear
      end
      rv = nil if rv.empty? && length != 0
    else
      read_all(rv)
    end
    rv
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
    sep = $/
    if sep.nil?
      read_all(rv = '')
      return rv.empty? ? nil : rv
    end
    re = /\A(.*?#{Regexp.escape(sep)})/

    begin
      @rbuf.sub!(re, '') and return $1
      return @rbuf.empty? ? nil : @rbuf.slice!(0, @rbuf.size) if eof?
      @socket.kgio_read(@@io_chunk_size, @buf) or eof!
      filter_body(once = '', @buf)
      @rbuf << once
    end while true
  end

  # :call-seq:
  #   ios.each { |line| block }  => ios
  #
  # Executes the block for every ``line'' in *ios*, where lines are
  # separated by the global record separator ($/, typically "\n").
  def each
    while line = gets
      yield line
    end

    self # Rack does not specify what the return value is here
  end

private

  def eof?
    if @parser.body_eof?
      while @chunked && ! @parser.parse
        once = @socket.kgio_read(@@io_chunk_size) or eof!
        @buf << once
      end
      @socket = nil
      true
    else
      false
    end
  end

  def filter_body(dst, src)
    rv = @parser.filter_body(dst, src)
    @bytes_read += dst.size
    rv
  end

  def read_all(dst)
    dst.replace(@rbuf)
    @socket or return
    until eof?
      @socket.kgio_read(@@io_chunk_size, @buf) or eof!
      filter_body(@rbuf, @buf)
      dst << @rbuf
    end
  ensure
    @rbuf.clear
  end

  def eof!
    # in case client only did a premature shutdown(SHUT_WR)
    # we do support clients that shutdown(SHUT_WR) after the
    # _entire_ request has been sent, and those will not have
    # raised EOFError on us.
    @socket.shutdown if @socket
  ensure
    raise Unicorn::ClientShutdown, "bytes_read=#{@bytes_read}", []
  end
end
