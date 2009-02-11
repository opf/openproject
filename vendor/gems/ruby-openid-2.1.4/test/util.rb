# Utilities that are only used in the testing code
require 'stringio'

module OpenID
  module TestUtil
    def assert_log_matches(*regexes)
      begin
        old_logger = Util.logger
        log_output = StringIO.new
        Util.logger = Logger.new(log_output)
        result = yield
      ensure
        Util.logger = old_logger
      end
      log_output.rewind
      log_lines = log_output.readlines
      assert_equal(regexes.length, log_lines.length,
                   [regexes, log_lines].inspect)
      log_lines.zip(regexes) do |line, regex|
        assert_match(regex, line)
      end
      result
    end

    def assert_log_line_count(num_lines)
      begin
        old_logger = Util.logger
        log_output = StringIO.new
        Util.logger = Logger.new(log_output)
        result = yield
      ensure
        Util.logger = old_logger
      end
      log_output.rewind
      log_lines = log_output.readlines
      assert_equal(num_lines, log_lines.length)
      result
    end

    def silence_logging
      begin
        old_logger = Util.logger
        log_output = StringIO.new
        Util.logger = Logger.new(log_output)
        result = yield
      ensure
        Util.logger = old_logger
      end
      result
    end
  end
end

