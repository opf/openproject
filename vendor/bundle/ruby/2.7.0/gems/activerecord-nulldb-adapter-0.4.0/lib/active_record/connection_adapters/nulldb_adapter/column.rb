class ActiveRecord::ConnectionAdapters::NullDBAdapter
  class Column < ::ActiveRecord::ConnectionAdapters::Column

    private

    def simplified_type(field_type)
      super || simplified_type_from_sql_type
    end

    def simplified_type_from_sql_type
      case sql_type
      when :primary_key
        :integer
      when :string
        :string
      end
    end

  end
end
