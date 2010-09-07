class CostQuery::Filter::PermissionFilter < CostQuery::Filter::Base
  dont_display!
  not_selectable!
  db_field ""

  initialize_query_with { |query| query.filter self.to_s.demodulize.to_sym }

  def permission_statement(permission)
    User.current.allowed_for(permission).gsub(/(user|project)s?\.id/, 'entries.\1_id')
  end
  
  def permission_for(type)
    "(entries.type != '#{type.capitalize}Entry' " \
    "OR #{permission_statement :"view_own_#{type}_entries"} " \
    "OR #{permission_statement :"view_#{type}_entries"})"
  end

  def sql_statement
    super.tap do |query|
      if User.current.admin?
        query.select :display_costs => '1'
      else
        query.where permission_for('time')
        query.where permission_for('cost')
        query.select :display_costs => "(#{permission_statement :view_hourly_rates} " \
          "AND #{permission_statement :view_cost_rates}) OR (#{permission_statement :view_own_hourly_rate})"
      end
    end
  end
end
