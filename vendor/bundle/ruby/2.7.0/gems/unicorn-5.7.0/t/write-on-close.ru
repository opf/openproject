class WriteOnClose
  def each(&block)
    @callback = block
  end

  def close
    @callback.call "7\r\nGoodbye\r\n0\r\n\r\n"
  end
end
use Rack::ContentType, "text/plain"
run(lambda { |_| [ 200, [%w(Transfer-Encoding chunked)], WriteOnClose.new ] })
