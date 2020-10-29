require 'minitest_helper'

describe 'class methods' do
  let(:lock_name) { 'test lock' }

  describe '.current_advisory_lock' do
    it 'returns nil outside an advisory lock request' do
      Tag.current_advisory_lock.must_be_nil
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        # The lock name may have a prefix if WITH_ADVISORY_LOCK_PREFIX env is set
        Tag.current_advisory_lock.must_match(/#{lock_name}/)
      end
    end

    it 'can obtain a lock with a name that attempts to disrupt a SQL comment' do
      dangerous_lock_name = 'test */ lock /*'
      Tag.with_advisory_lock(dangerous_lock_name) do
        Tag.current_advisory_lock.must_match(/#{Regexp.escape(dangerous_lock_name)}/)
      end

    end
  end

  describe '.advisory_lock_exists?' do
    it 'returns false for an unacquired lock' do
      Tag.advisory_lock_exists?(lock_name).must_be_false
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        Tag.advisory_lock_exists?(lock_name).must_be_true
      end
    end
  end

  describe 'zero timeout_seconds' do
    it 'attempts the lock exactly once with no timeout' do
      expected = SecureRandom.base64
      Tag.with_advisory_lock(lock_name, 0) do
        expected
      end.must_equal expected
    end
  end
end
