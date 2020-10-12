class CostEntry
  module CostEntryScopes
    include ::CostScopes

    def view_allowed_entries_permission
      :view_cost_entries
    end

    def view_allowed_own_entries_permission
      :view_own_cost_entries
    end

    def view_rates_permissions
      :view_cost_rates
    end
  end
end
