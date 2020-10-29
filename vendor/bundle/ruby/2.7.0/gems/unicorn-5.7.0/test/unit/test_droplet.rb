require 'test/unit'
require 'unicorn'

class TestDroplet < Test::Unit::TestCase
  def test_create_many_droplets
    now = Time.now.to_i
    (0..1024).each do |i|
      droplet = Unicorn::Worker.new(i)
      assert droplet.respond_to?(:tick)
      assert_equal 0, droplet.tick
      assert_equal(now, droplet.tick = now)
      assert_equal now, droplet.tick
      assert_equal(0, droplet.tick = 0)
      assert_equal 0, droplet.tick
    end
  end

  def test_shared_process
    droplet = Unicorn::Worker.new(0)
    _, status = Process.waitpid2(fork { droplet.tick += 1; exit!(0) })
    assert status.success?, status.inspect
    assert_equal 1, droplet.tick

    _, status = Process.waitpid2(fork { droplet.tick += 1; exit!(0) })
    assert status.success?, status.inspect
    assert_equal 2, droplet.tick
  end
end
