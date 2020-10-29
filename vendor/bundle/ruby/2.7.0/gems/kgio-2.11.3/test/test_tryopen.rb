require 'tempfile'
require 'test/unit'
$-w = true
require 'kgio'

class TestTryopen < Test::Unit::TestCase

  def test_tryopen_success
    tmp = Kgio::File.tryopen(__FILE__)

    tmp.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, tmp.close_on_exec?)

    assert_kind_of File, tmp
    assert_equal File.read(__FILE__), tmp.read
    assert_equal __FILE__, tmp.path
    assert_equal __FILE__, tmp.to_path
    tmp.close
  end

  def test_tryopen_ENOENT
    tmp = Tempfile.new "tryopen"
    path = tmp.path
    tmp.close!
    tmp = Kgio::File.tryopen(path)
    assert_equal :ENOENT, tmp
  end

  def test_tryopen_EACCES
    tmp = Tempfile.new "tryopen"
    File.chmod 0000, tmp.path
    tmp = Kgio::File.tryopen(tmp.path)
    if Process.euid == 0
      assert_kind_of Kgio::File, tmp
      warn "cannot test EACCES when euid == 0"
    else
      assert_equal(:EACCES, tmp)
    end
  end

  def test_tryopen_readwrite
    tmp = Tempfile.new "tryopen"
    file = Kgio::File.tryopen(tmp.path, IO::RDWR)
    file.syswrite "FOO"
    assert_equal "FOO", tmp.sysread(3)
  end

  def test_tryopen_try_readwrite
    tmp = Tempfile.new "tryopen"
    file = Kgio::File.tryopen(tmp.path, IO::RDWR)
    assert_nil file.kgio_trywrite("FOO")
    file.rewind
    assert_equal "FOO", file.kgio_tryread(3)
  end

  def test_tryopen_mode
    tmp = Tempfile.new "tryopen"
    path = tmp.path
    tmp.close!
    file = Kgio::File.tryopen(path, IO::RDWR|IO::CREAT, 0000)
    assert_equal 0100000, File.stat(path).mode
    file.close
  ensure
    File.unlink path
  end

  require "benchmark"
  def test_benchmark
    nr = 1000000
    tmp = Tempfile.new('tryopen')
    file = tmp.path
    Benchmark.bmbm do |x|
      x.report("tryopen (OK)") do
        nr.times { Kgio::File.tryopen(file).close }
      end
      x.report("open (OK)") do
        nr.times { File.readable?(file) && File.open(file).close }
      end
    end
    tmp.close!
    assert_equal :ENOENT, Kgio::File.tryopen(file)
    Benchmark.bmbm do |x|
      x.report("tryopen (ENOENT)") do
        nr.times { Kgio::File.tryopen(file) }
      end
      x.report("open (ENOENT)") do
        nr.times { File.readable?(file) && File.open(file) }
      end
    end
  end if ENV["BENCHMARK"]
end
