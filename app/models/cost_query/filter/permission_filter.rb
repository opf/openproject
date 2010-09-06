class CostQuery::Filter::PermissionFilter < CostQuery::Filter::Base
  dont_display!
  not_selectable!
  db_field ""

  initialize_query_with { |query| query.filter self.to_s.demodulize.to_sym }

  def permission_statement(permission)
    User.current.allowed_for(permission).gsub(/(user|project)s?\.id/, 'entries.\1_id')
  end

  def sql_statement
    super.tap do |query|
      query.where "(entries.type != \"TimeEntry\" OR #{permission_statement :view_own_time_entries} OR #{permission_statement :view_time_entries})"
      query.where "(entries.type != \"CostEntry\" OR #{permission_statement :view_own_cost_entries} OR #{permission_statement :view_cost_entries})"
      query.select "*"
      query.select :display_costs => "(#{permission_statement :view_hourly_rates} AND #{permission_statement :view_cost_rates}) OR (#{permission_statement :view_own_hourly_rate}))"
    end
  end
end
