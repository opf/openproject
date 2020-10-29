require 'minitest_helper'

describe 'separate thread tests' do
  let(:lock_name) { 'testing 1,2,3' } # OMG COMMAS

  before do
    @mutex = Mutex.new
    @t1_acquired_lock = false
    @t1_return_value = nil

    @t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        @t1_return_value = Label.with_advisory_lock(lock_name) do
          @mutex.synchronize { @t1_acquired_lock = true }
          sleep
          't1 finished'
        end
      end
    end

    # Wait for the thread to acquire the lock:
    until @mutex.synchronize { @t1_acquired_lock } do
      sleep(0.1)
    end
    ActiveRecord::Base.connection.reconnect!
  end

  after do
    @t1.wakeup if @t1.status == 'sleep'
    @t1.join
  end

  it '#with_advisory_lock with a 0 timeout returns false immediately' do
    response = Label.with_advisory_lock(lock_name, 0) do
      fail 'should not be yielded to'
    end
    response.must_be_false
  end

  it '#with_advisory_lock yields to the provided block' do
    @t1_acquired_lock.must_be_true
  end

  it '#advisory_lock_exists? returns true when another thread has the lock' do
    Tag.advisory_lock_exists?(lock_name).must_be_true
  end

  it 'can re-establish the lock after the other thread releases it' do
    @t1.wakeup
    @t1.join
    @t1_return_value.must_equal 't1 finished'

    # We should now be able to acquire the lock immediately:
    reacquired = false
    Label.with_advisory_lock(lock_name, 0) do
      reacquired = true
    end.must_be_true
    reacquired.must_be_true
  end
end
