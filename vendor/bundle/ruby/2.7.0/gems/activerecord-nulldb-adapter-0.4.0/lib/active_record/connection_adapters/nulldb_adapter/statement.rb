class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class Statement
    attr_reader :entry_point, :content

    def initialize(entry_point, content = "")
      @entry_point, @content = entry_point, content
    end

    def ==(other)
      self.entry_point == other.entry_point
    end
  end

end
