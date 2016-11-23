class WorkPackage
  class LaborCosts < AbstractCosts
    def costs_model
      TimeEntry
    end

    def filter_authorized(scope)
      TimeEntry.with_visible_costs_on scope
    end

    ##
    # As the core already selects time_entries, we can simply
    # steal the extra column here.
    def add_to_work_package_collection(scope)
      scope.select("#{costs_sum} AS #{costs_sum_alias}")
    end

    def costs_sum_alias
      'time_entries_sum'
    end
  end
end
