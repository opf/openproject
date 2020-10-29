# -*- encoding: binary -*-
require 'test/unit'
require 'raindrops'
require 'socket'
require 'benchmark'
$stderr.sync = $stdout.sync = true

class TestLinuxAllTcpListenStatsLeak < Test::Unit::TestCase

  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'


  def rss_kb
    File.readlines("/proc/#$$/status").grep(/VmRSS:/)[0].split(/\s+/)[1].to_i
  end
  def test_leak
    s = TCPServer.new(TEST_ADDR, 0)
    start_kb = rss_kb
    p [ :start_kb, start_kb ]
    assert_nothing_raised do
      p(Benchmark.measure {
        1000.times { Raindrops::Linux.all_tcp_listener_stats }
      })
    end
    cur_kb = rss_kb
    p [ :cur_kb, cur_kb ]
    now = Time.now.to_i
    fin = now + 60
    assert_nothing_raised do
      1000000000.times { |i|
        if (i % 1024) == 0
          now = Time.now.to_i
          break if now > fin
        end
        Raindrops::Linux.all_tcp_listener_stats
      }
    end
    cur_kb = rss_kb
    p [ :cur_kb, cur_kb ]
  ensure
    s.close
  end
end if ENV["STRESS"].to_i != 0
