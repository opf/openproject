require 'stringio'

class DeprecationMatcher
  def initialize(message)
    @message = message
  end

  def matches?(block)
    @actual = hijack_stderr(&block)
    PhraseMatcher.new("DEPRECATION WARNING: #{@message}").matches?(@actual)
  end

  def failure_message
    "expected deprecation warning #{@message.inspect}, got #{@actual.inspect}"
  end

  private

  def hijack_stderr
    err = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string.rstrip
  ensure
    $stderr = err
  end
end
