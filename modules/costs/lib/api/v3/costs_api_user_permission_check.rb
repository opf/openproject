module API::V3::CostsApiUserPermissionCheck
  def overall_costs_visible?
    (user_has_time_entry_permissions? && user_has_hourly_rate_permissions?) ||
      (user_has_cost_entry_permissions? && user_has_cost_rates_permission?)
  end

  def labor_costs_visible?
    user_has_time_entry_permissions? && user_has_hourly_rate_permissions?
  end

  def material_costs_visible?
    user_has_cost_entry_permissions? && user_has_cost_rates_permission?
  end

  def costs_by_type_visible?
    user_has_cost_entry_permissions?
  end

  def spent_time_visible?
    user_has_time_entry_permissions?
  end

  def cost_object_visible?
    user_has_cost_object_permissions?
  end

  # overriding core's method to also factor in :view_own_time_entries
  def view_time_entries_allowed?
    user_has_time_entry_permissions?
  end

  private

  def user_has_time_entry_permissions?
    current_user_allowed_to(:view_time_entries, context: represented.project) ||
      current_user_allowed_to(:view_own_time_entries, context: represented.project)
  end

  def user_has_hourly_rate_permissions?
    current_user_allowed_to(:view_hourly_rates, context: represented.project) ||
      current_user_allowed_to(:view_own_hourly_rate, context: represented.project)
  end

  def user_has_cost_rates_permission?
    current_user_allowed_to(:view_cost_rates, context: represented.project)
  end

  def user_has_cost_entry_permissions?
    current_user_allowed_to(:view_own_cost_entries, context: represented.project) ||
      current_user_allowed_to(:view_cost_entries, context: represented.project)
  end

  def user_has_cost_object_permissions?
    current_user_allowed_to(:view_cost_objects, context: represented.project)
  end
end
