# coding: utf-8

require "test-unit"
require "testunit-test-util"

class TestCodeSnippet < Test::Unit::TestCase
  include TestUnitTestUtil

  class TestJRuby < self
    def test_error_inside_jruby
      jruby_only_test

      backtrace = backtrace_from_jruby
      no_rb_entries = backtrace.find_all do |(file, _, _)|
        File.extname(file) != ".rb"
      end

      fetcher = Test::Unit::CodeSnippetFetcher.new
      snippets = no_rb_entries.collect do |(file, line, _)|
        fetcher.fetch(file, line)
      end
      assert_equal([[]] * no_rb_entries.size,
                   snippets)
    end

    private
    def backtrace_from_jruby
      begin
        java.util.Vector.new(-1)
      rescue Exception
        $@.collect do |entry|
          entry.split(/:/, 3)
        end
      else
        flunk("failed to raise an exception from JRuby.")
      end
    end
  end

  class TestDefaultExternal < self
    def suppress_warning
      verbose = $VERBOSE
      begin
        $VERBOSE = false
        yield
      ensure
        $VERBOSE = verbose
      end
    end

    def setup
      suppress_warning do
        @default_external = Encoding.default_external
      end
      @fetcher = Test::Unit::CodeSnippetFetcher.new
    end

    def teardown
      suppress_warning do
        Encoding.default_external = @default_external
      end
    end

    def test_windows_31j
      source = Tempfile.new(["test-code-snippet", ".rb"])
      source.puts(<<-SOURCE)
puts("あいうえお")
      SOURCE
      source.flush
      suppress_warning do
        Encoding.default_external = "Windows-31J"
      end
      assert_equal([
                     [1, "puts(\"あいうえお\")", {:target_line? => false}],
                   ],
                   @fetcher.fetch(source.path, 0))
    end
  end
end
