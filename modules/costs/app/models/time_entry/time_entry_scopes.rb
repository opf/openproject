class TimeEntry
  module TimeEntryScopes
    include ::CostScopes

    def view_allowed_entries_permission
      :view_time_entries
    end

    def view_allowed_own_entries_permission
      :view_own_time_entries
    end

    def with_visible_rates_on(scope, user: User.current)
      table = self.arel_table

      view_allowed = Project.allowed_to(user, :view_hourly_rates).select(:id)
      view_own_allowed = Project.allowed_to(user, :view_own_hourly_rate).select(:id)

      scope.where view_or_view_own(table, view_allowed, view_own_allowed, user)
    end
  end
end
