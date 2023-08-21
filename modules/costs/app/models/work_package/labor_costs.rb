class WorkPackage
  class LaborCosts < AbstractCosts
    def costs_model
      TimeEntry
    end

    def filter_authorized(scope)
      TimeEntry.with_visible_costs_on scope
    end

    def costs_sum_alias
      'time_entries_sum'
    end

    def subselect_alias
      'time_entries'
    end

    def sum_subselect(base_scope)
      super
    end
  end
end
