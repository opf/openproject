class WorkPackage
  class MaterialCosts < AbstractCosts
    def costs_model
      CostEntry
    end

    def filter_authorized(scope)
      CostEntry.with_visible_costs_on scope
    end
  end
end
