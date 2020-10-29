unless respond_to?(:tap)
  class Object
    def tap
      yield self
      self
    end
  end
end

unless respond_to?(:try)
  class Object
    def try(*a, &b)
      if a.empty? && block_given?
        yield self
      else
        __send__(*a, &b)
      end
    end
  end

  class NilClass
    def try(*args); nil; end
  end
end

class ActiveRecord::Base
  # Instantiate a new NullDB connection.  Used by ActiveRecord internally.
  def self.nulldb_connection(config)
    ActiveRecord::ConnectionAdapters::NullDBAdapter.new(config)
  end
end