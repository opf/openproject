class WorkPackage
  class LaborCosts < AbstractCosts
    def costs_model
      TimeEntry
    end

    def filter_authorized(scope)
      TimeEntry.with_visible_costs_on scope
    end
  end
end
