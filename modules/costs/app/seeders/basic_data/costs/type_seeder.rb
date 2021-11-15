module BasicData
  module Costs
    module TypeSeeder
      # TODO: split up between costs and budgets
      def coded_visibility_table
        super.merge costs_visibility_table
      end

      ##
      # Relies on type names in the core TypeSeeder being (in this order)
      #   task, milestone, phase, feature, epic, user_story, bug
      # and 0 to 2 being mapped to
      #   hidden, default, visible
      def costs_visibility_table
        {
          overall_costs: [1, 1, 1, 1, 1, 1, 1],
          material_costs: [1, 1, 1, 1, 1, 1, 1], # unit costs
          labor_costs: [1, 1, 1, 1, 1, 1, 1],
          budget: [1, 1, 1, 1, 1, 1, 1]  # budget
        }
      end
    end

    BasicData::TypeSeeder.prepend BasicData::Costs::TypeSeeder
  end
end
