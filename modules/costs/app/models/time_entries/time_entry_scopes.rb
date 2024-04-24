module TimeEntries
  module TimeEntryScopes
    include ::CostScopes

    def view_allowed_entries_permission
      :view_time_entries
    end

    def view_allowed_own_entries_permission
      :view_own_time_entries
    end

    def with_visible_rates_on(scope, user: User.current)
      table = arel_table
      scope.where(view_or_view_own(table, :view_hourly_rates, :view_own_hourly_rate, user))
    end
  end
end
