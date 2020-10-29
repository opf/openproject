class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class Checkpoint < Statement
    def initialize
      super(:checkpoint, "")
    end

    def ==(other)
      self.class == other.class
    end
  end

end
