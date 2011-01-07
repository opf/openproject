class Report::GroupBy
  class SingletonValue < Base
    dont_display!

    put_sql_table_names "singleton_value" => false

    def define_group(sql)
      sql.select "1 as singleton_value"
      sql.group_by "singleton_value"
    end
  end
end
