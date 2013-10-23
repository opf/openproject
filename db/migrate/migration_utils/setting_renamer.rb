module Migration
  class SettingRenamer

    #define all the following methods as class methods
    class << self

      def rename(source_name, target_name)
        ActiveRecord::Base.connection.execute <<-SQL
            UPDATE #{settings_table}
            SET name = #{quote_value(target_name)}
            WHERE name = #{quote_value(source_name)}
          SQL
      end


    private

      def settings_table
        @settings_table ||= ActiveRecord::Base.connection.quote_table_name('settings')
      end

      def quote_value s
        ActiveRecord::Base.connection.quote(s)
      end

    end
  end
end

