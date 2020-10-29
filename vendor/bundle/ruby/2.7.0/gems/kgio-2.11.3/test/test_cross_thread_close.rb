require 'test/unit'
$-w = true
require 'kgio'

class TestCrossThreadClose < Test::Unit::TestCase

  def test_cross_thread_close
    host = ENV["TEST_HOST"] || '127.0.0.1'
    srv = Kgio::TCPServer.new(host, 0)
    thr = Thread.new do
      begin
        srv.kgio_accept
      rescue => e
        e
      end
    end
    sleep(0.1) until thr.stop?
    srv.close
    unless defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" &&
           RUBY_VERSION == "1.9.3"
      thr.run rescue nil
    end
    thr.join
    assert_kind_of IOError, thr.value
  end
end if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
