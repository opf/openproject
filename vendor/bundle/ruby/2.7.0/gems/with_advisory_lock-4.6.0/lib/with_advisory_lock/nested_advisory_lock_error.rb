module WithAdvisoryLock
  class NestedAdvisoryLockError < StandardError
    attr_accessor :lock_stack

    def initialize(msg = nil, lock_stack = nil)
      super(msg)
      @lock_stack = lock_stack
    end

    def to_s
      super + (lock_stack ? ": lock stack = #{lock_stack}" : '')
    end
  end
end
