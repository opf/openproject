# -*- encoding: binary -*-

require 'test/unit'
require 'tempfile'
require 'unicorn'

TestStruct = Struct.new(
  *(Unicorn::Configurator::DEFAULTS.keys + %w(listener_opts listeners)))
class TestConfigurator < Test::Unit::TestCase

  def test_config_init
    Unicorn::Configurator.new {}
  end

  def test_expand_addr
    meth = Unicorn::Configurator.new.method(:expand_addr)

    assert_equal "/var/run/unicorn.sock", meth.call("/var/run/unicorn.sock")
    assert_equal "#{Dir.pwd}/foo/bar.sock", meth.call("unix:foo/bar.sock")

    path = meth.call("~/foo/bar.sock")
    assert_equal "/", path[0..0]
    assert_match %r{/foo/bar\.sock\z}, path

    path = meth.call("~root/foo/bar.sock")
    assert_equal "/", path[0..0]
    assert_match %r{/foo/bar\.sock\z}, path

    assert_equal "1.2.3.4:2007", meth.call('1.2.3.4:2007')
    assert_equal "0.0.0.0:2007", meth.call('0.0.0.0:2007')
    assert_equal "0.0.0.0:2007", meth.call(':2007')
    assert_equal "0.0.0.0:2007", meth.call('*:2007')
    assert_equal "0.0.0.0:2007", meth.call('2007')
    assert_equal "0.0.0.0:2007", meth.call(2007)

    %w([::1]:2007 [::]:2007).each do |addr|
      assert_equal addr, meth.call(addr.dup)
    end

    # for Rainbows! users only
    assert_equal "[::]:80", meth.call("[::]")
    assert_equal "127.6.6.6:80", meth.call("127.6.6.6")

    # the next two aren't portable, consider them unsupported for now
    # assert_match %r{\A\d+\.\d+\.\d+\.\d+:2007\z}, meth.call('1:2007')
    # assert_match %r{\A\d+\.\d+\.\d+\.\d+:2007\z}, meth.call('2:2007')
  end

  def test_config_invalid
    tmp = Tempfile.new('unicorn_config')
    tmp.syswrite(%q(asdfasdf "hello-world"))
    assert_raises(NoMethodError) do
      Unicorn::Configurator.new(:config_file => tmp.path)
    end
  end

  def test_config_non_existent
    tmp = Tempfile.new('unicorn_config')
    path = tmp.path
    tmp.close!
    assert_raises(Errno::ENOENT) do
      Unicorn::Configurator.new(:config_file => path)
    end
  end

  def test_config_defaults
    cfg = Unicorn::Configurator.new(:use_defaults => true)
    test_struct = TestStruct.new
    cfg.commit!(test_struct)
    Unicorn::Configurator::DEFAULTS.each do |key,value|
      assert_equal value, test_struct.__send__(key)
    end
  end

  def test_config_defaults_skip
    cfg = Unicorn::Configurator.new(:use_defaults => true)
    skip = [ :logger ]
    test_struct = TestStruct.new
    cfg.commit!(test_struct, :skip => skip)
    Unicorn::Configurator::DEFAULTS.each do |key,value|
      next if skip.include?(key)
      assert_equal value, test_struct.__send__(key)
    end
    assert_nil test_struct.logger
  end

  def test_listen_options
    tmp = Tempfile.new('unicorn_config')
    expect = { :sndbuf => 1, :rcvbuf => 2, :backlog => 10 }.freeze
    listener = "127.0.0.1:12345"
    tmp.syswrite("listen '#{listener}', #{expect.inspect}\n")
    cfg = Unicorn::Configurator.new(:config_file => tmp.path)
    test_struct = TestStruct.new
    cfg.commit!(test_struct)
    assert(listener_opts = test_struct.listener_opts)
    assert_equal expect, listener_opts[listener]
  end

  def test_listen_option_bad
    tmp = Tempfile.new('unicorn_config')
    expect = { :sndbuf => "five" }
    listener = "127.0.0.1:12345"
    tmp.syswrite("listen '#{listener}', #{expect.inspect}\n")
    assert_raises(ArgumentError) do
      Unicorn::Configurator.new(:config_file => tmp.path)
    end
  end

  def test_listen_option_bad_delay
    tmp = Tempfile.new('unicorn_config')
    expect = { :delay => "five" }
    listener = "127.0.0.1:12345"
    tmp.syswrite("listen '#{listener}', #{expect.inspect}\n")
    assert_raises(ArgumentError) do
      Unicorn::Configurator.new(:config_file => tmp.path)
    end
  end

  def test_listen_option_float_delay
    tmp = Tempfile.new('unicorn_config')
    expect = { :delay => 0.5 }
    listener = "127.0.0.1:12345"
    tmp.syswrite("listen '#{listener}', #{expect.inspect}\n")
    Unicorn::Configurator.new(:config_file => tmp.path)
  end

  def test_listen_option_int_delay
    tmp = Tempfile.new('unicorn_config')
    expect = { :delay => 5 }
    listener = "127.0.0.1:12345"
    tmp.syswrite("listen '#{listener}', #{expect.inspect}\n")
    Unicorn::Configurator.new(:config_file => tmp.path)
  end

  def test_check_client_connection
    tmp = Tempfile.new('unicorn_config')
    test_struct = TestStruct.new
    tmp.syswrite("check_client_connection true\n")

    assert_nothing_raised do
      Unicorn::Configurator.new(:config_file => tmp.path).commit!(test_struct)
    end

    assert test_struct.check_client_connection
  end

  def test_check_client_connection_with_tcp_bad
    tmp = Tempfile.new('unicorn_config')
    test_struct = TestStruct.new
    listener = "127.0.0.1:12345"
    tmp.syswrite("check_client_connection true\n")
    tmp.syswrite("listen '#{listener}', :tcp_nopush => true\n")

    assert_raises(ArgumentError) do
      Unicorn::Configurator.new(:config_file => tmp.path).commit!(test_struct)
    end
  end

  def test_after_fork_proc
    test_struct = TestStruct.new
    [ proc { |a,b| }, Proc.new { |a,b| }, lambda { |a,b| } ].each do |my_proc|
      Unicorn::Configurator.new(:after_fork => my_proc).commit!(test_struct)
      assert_equal my_proc, test_struct.after_fork
    end
  end

  def test_after_fork_wrong_arity
    [ proc { |a| }, Proc.new { }, lambda { |a,b,c| } ].each do |my_proc|
      assert_raises(ArgumentError) do
        Unicorn::Configurator.new(:after_fork => my_proc)
      end
    end
  end

end
