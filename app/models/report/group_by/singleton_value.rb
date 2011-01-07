class Report::GroupBy
  class SingletonValue < Base
    dont_display!

    def define_group(sql)
      sql.select "1 as singleton_value"
      sql.group_by "singleton_value"
    end
  end
end
