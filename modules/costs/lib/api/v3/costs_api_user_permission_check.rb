module API::V3::CostsApiUserPermissionCheck
  def overall_costs_visible?
    (view_time_entries_allowed? && user_has_hourly_rate_permissions?) ||
      (user_has_cost_entry_permissions? && user_has_cost_rates_permission?)
  end

  def labor_costs_visible?
    view_time_entries_allowed? && user_has_hourly_rate_permissions?
  end

  def material_costs_visible?
    user_has_cost_entry_permissions? && user_has_cost_rates_permission?
  end

  def costs_by_type_visible?
    user_has_cost_entry_permissions?
  end

  def spent_time_visible?
    view_time_entries_allowed?
  end

  private

  def user_has_hourly_rate_permissions?
    current_user.allowed_in_project?(:view_hourly_rates, represented.project) ||
    current_user.allowed_in_project?(:view_own_hourly_rate, represented.project)
  end

  def user_has_cost_rates_permission?
    current_user.allowed_in_project?(:view_cost_rates, represented.project)
  end

  def user_has_cost_entry_permissions?
    current_user.allowed_in_project?(:view_own_cost_entries, represented.project) ||
    current_user.allowed_in_project?(:view_cost_entries, represented.project)
  end
end
