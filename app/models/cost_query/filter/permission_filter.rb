class CostQuery::Filter::PermissionFilter < Report::Filter::Base
  dont_display!
  not_selectable!
  db_field ""
  singleton

  initialize_query_with { |query| query.filter self.to_s.demodulize.to_sym }

  def permission_statement(permission)
    User.current.allowed_to_condition_with_project_id(permission).gsub(/(user|project)s?\.id/, '\1_id')
  end

  def permission_for(type)
    "((#{permission_statement :"view_own_#{type}_entries"} AND user_id = #{User.current.id}) " \
    "OR #{permission_statement :"view_#{type}_entries"})"
  end

  def display_costs
    "(#{permission_statement :view_hourly_rates} " \
    "AND #{permission_statement :view_cost_rates}) " \
    "OR " \
    "(#{permission_statement :view_own_hourly_rate} " \
    "AND type = 'TimeEntry' AND user_id = #{User.current.id}) " \
    "OR " \
    "(#{permission_statement :view_cost_rates} " \
    "AND type = 'CostEntry' AND user_id = #{User.current.id})"
  end

  def sql_statement
    super.tap do |query|
      query.from.each_subselect do |sub|
        sub.where permission_for(sub == query.from.first ? 'time' : 'cost')
        sub.select.delete_if { |f| f.end_with? "display_costs" }
        sub.select :display_costs => switch(display_costs => '1', :else => 0)
      end
    end
  end
end
