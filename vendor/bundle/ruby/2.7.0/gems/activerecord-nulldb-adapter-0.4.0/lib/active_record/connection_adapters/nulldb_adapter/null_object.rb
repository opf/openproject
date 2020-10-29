class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class NullObject
    def method_missing(*args, &block)
      nil
    end

    def to_a
      []
    end
  end

end
