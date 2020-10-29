class PhraseMatcher
  def initialize(string)
    @string = string
    @pattern = /\b#{Regexp.escape string}\b/
  end

  def matches?(actual)
    @actual = actual.to_s
    @actual =~ @pattern
  end

  def failure_message
    "expected #{@actual.inspect} to contain phrase #{@string.inspect}"
  end

  def negative_failure_message
    "expected #{@actual.inspect} not to contain phrase #{@string.inspect}"
  end
end
