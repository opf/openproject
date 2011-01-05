class Report::GroupBy
  class SingletonValue < Base
    dont_display!

    def all_group_fields(prefix = true)
      parent_fields = parent.all_group_fields if parent
      #TODO: differenciate between all_group_fields and all_select_fields
      (parent_fields || []) << ['1 as singleton_value', 'singleton_value']
    end

    def define_group(sql)
      sql.select "1 as singleton_value"
      sql.group_by "singleton_value"
    end
  end
end
