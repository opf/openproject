require 'minitest_helper'

describe 'shared locks' do
  def supported?
    env_db != :mysql
  end

  class SharedTestWorker
    def initialize(shared)
      @shared = shared

      @locked = nil
      @cleanup = false
      @thread = Thread.new { work }
    end

    def locked?
      sleep 0.01 while @locked.nil? && @thread.alive?
      @locked
    end

    def cleanup!
      @cleanup = true
      @thread.join
      raise if @thread.status.nil?
    end

    private

    def work
      ActiveRecord::Base.connection_pool.with_connection do
        Tag.with_advisory_lock('test', timeout_seconds: 0, shared: @shared) do
          @locked = true
          sleep 0.01 until @cleanup
        end
        @locked = false
        sleep 0.01 until @cleanup
      end
    end
  end

  it 'does not allow two exclusive locks' do
    one = SharedTestWorker.new(false)
    one.locked?.must_equal true

    two = SharedTestWorker.new(false)
    two.locked?.must_equal false

    one.cleanup!
    two.cleanup!
  end

  describe 'not supported' do
    before do
      skip if supported?
    end

    it 'raises an error when attempting to use a shared lock' do
      one = SharedTestWorker.new(true)
      one.locked?.must_be_nil
      exception = proc {
        one.cleanup!
      }.must_raise ArgumentError
      exception.message.must_include 'not supported'
    end
  end

  describe 'supported' do
    before do
      skip unless supported?
    end

    it 'does allow two shared locks' do
      one = SharedTestWorker.new(true)
      one.locked?.must_equal true

      two = SharedTestWorker.new(true)
      two.locked?.must_equal true

      one.cleanup!
      two.cleanup!
    end

    it 'does not allow exclusive lock with shared lock' do
      one = SharedTestWorker.new(true)
      one.locked?.must_equal true

      two = SharedTestWorker.new(false)
      two.locked?.must_equal false

      three = SharedTestWorker.new(true)
      three.locked?.must_equal true

      one.cleanup!
      two.cleanup!
      three.cleanup!
    end

    it 'does not allow shared lock with exclusive lock' do
      one = SharedTestWorker.new(false)
      one.locked?.must_equal true

      two = SharedTestWorker.new(true)
      two.locked?.must_equal false

      one.cleanup!
      two.cleanup!
    end

    describe 'PostgreSQL' do
      before do
        skip unless env_db == :postgresql
      end

      def pg_lock_modes
        ActiveRecord::Base.connection.select_values("SELECT mode FROM pg_locks WHERE locktype = 'advisory';")
      end

      it 'allows shared lock to be upgraded to an exclusive lock' do
        pg_lock_modes.must_equal %w[]
        Tag.with_advisory_lock 'test', shared: true do
          pg_lock_modes.must_equal %w[ShareLock]
          Tag.with_advisory_lock 'test', shared: false do
            pg_lock_modes.must_equal %w[ShareLock ExclusiveLock]
          end
        end
        pg_lock_modes.must_equal %w[]
      end
    end
  end
end
