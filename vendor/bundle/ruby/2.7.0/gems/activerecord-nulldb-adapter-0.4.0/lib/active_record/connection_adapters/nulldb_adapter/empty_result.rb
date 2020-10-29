class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class EmptyResult < Array
    attr_reader :column_types
    
    def bind_column_meta(columns)
      @columns = columns
      return if columns.empty?

      @column_types = columns.reduce({}) do |ctypes, col|
        ctypes[col.name] = ActiveRecord::Type.lookup(col.type)
        ctypes
      end      
    end

    def columns
      @columns ||= []
    end

    def column_types
      @column_types ||= {}
    end

    def cast_values(type_overrides = nil)
      rows
    end

    def rows
      []
    end

    def >(num)
      rows.size > num
    end

    def includes_column?(name)
      false
    end
  end

end
