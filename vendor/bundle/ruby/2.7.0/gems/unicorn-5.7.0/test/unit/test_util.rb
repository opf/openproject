# -*- encoding: binary -*-

require './test/test_helper'
require 'tempfile'

class TestUtil < Test::Unit::TestCase

  EXPECT_FLAGS = File::WRONLY | File::APPEND
  def test_reopen_logs_noop
    tmp = Tempfile.new('')
    fp = File.open(tmp.path, 'ab')
    fp.sync = true
    ext = fp.external_encoding rescue nil
    int = fp.internal_encoding rescue nil
    before = fp.stat.inspect
    Unicorn::Util.reopen_logs
    assert_equal before, File.stat(fp.path).inspect
    assert_equal ext, (fp.external_encoding rescue nil)
    assert_equal int, (fp.internal_encoding rescue nil)
    assert_equal(EXPECT_FLAGS, EXPECT_FLAGS & fp.fcntl(Fcntl::F_GETFL))
    tmp.close!
    fp.close
  end

  def test_reopen_logs_renamed
    tmp = Tempfile.new('')
    tmp_path = tmp.path.freeze
    fp = File.open(tmp_path, 'ab')
    fp.sync = true

    ext = fp.external_encoding rescue nil
    int = fp.internal_encoding rescue nil
    before = fp.stat.inspect
    to = Tempfile.new('')
    File.rename(tmp_path, to.path)
    assert ! File.exist?(tmp_path)
    Unicorn::Util.reopen_logs
    assert_equal tmp_path, tmp.path
    assert File.exist?(tmp_path)
    assert before != File.stat(tmp_path).inspect
    assert_equal fp.stat.inspect, File.stat(tmp_path).inspect
    assert_equal ext, (fp.external_encoding rescue nil)
    assert_equal int, (fp.internal_encoding rescue nil)
    assert_equal(EXPECT_FLAGS, EXPECT_FLAGS & fp.fcntl(Fcntl::F_GETFL))
    assert fp.sync
    tmp.close!
    to.close!
    fp.close
  end

  def test_reopen_logs_renamed_with_encoding
    tmp = Tempfile.new('')
    tmp_path = tmp.path.dup.freeze
    Encoding.list.each { |encoding|
      File.open(tmp_path, "a:#{encoding.to_s}") { |fp|
        fp.sync = true
        assert_equal encoding, fp.external_encoding
        assert_nil fp.internal_encoding
        File.unlink(tmp_path)
        assert ! File.exist?(tmp_path)
        Unicorn::Util.reopen_logs
        assert_equal tmp_path, fp.path
        assert File.exist?(tmp_path)
        assert_equal fp.stat.inspect, File.stat(tmp_path).inspect
        assert_equal encoding, fp.external_encoding
        assert_nil fp.internal_encoding
        assert_equal(EXPECT_FLAGS, EXPECT_FLAGS & fp.fcntl(Fcntl::F_GETFL))
        assert fp.sync
      }
    }
    tmp.close!
  end

  def test_reopen_logs_renamed_with_internal_encoding
    tmp = Tempfile.new('')
    tmp_path = tmp.path.dup.freeze
    Encoding.list.each { |ext|
      Encoding.list.each { |int|
        next if ext == int
        File.open(tmp_path, "a:#{ext.to_s}:#{int.to_s}") { |fp|
          fp.sync = true
          assert_equal ext, fp.external_encoding

          if ext != Encoding::BINARY
            assert_equal int, fp.internal_encoding
          end

          File.unlink(tmp_path)
          assert ! File.exist?(tmp_path)
          Unicorn::Util.reopen_logs
          assert_equal tmp_path, fp.path
          assert File.exist?(tmp_path)
          assert_equal fp.stat.inspect, File.stat(tmp_path).inspect
          assert_equal ext, fp.external_encoding
          if ext != Encoding::BINARY
            assert_equal int, fp.internal_encoding
          end
          assert_equal(EXPECT_FLAGS, EXPECT_FLAGS & fp.fcntl(Fcntl::F_GETFL))
          assert fp.sync
        }
      }
    }
    tmp.close!
  end

  def test_pipe
    r, w = Unicorn.pipe
    assert r
    assert w

    return if RUBY_PLATFORM !~ /linux/

    begin
      f_getpipe_sz = 1032
      IO.pipe do |a, b|
        a_sz = a.fcntl(f_getpipe_sz)
        b.fcntl(f_getpipe_sz)
        assert_kind_of Integer, a_sz
        r_sz = r.fcntl(f_getpipe_sz)
        assert_equal Raindrops::PAGE_SIZE, r_sz
        assert_operator a_sz, :>=, r_sz
      end
    rescue Errno::EINVAL
      # Linux <= 2.6.34
    end
  ensure
    w.close
    r.close
  end
end
