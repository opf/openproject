module BasicData
  module Backlogs
    module TypeSeeder
      def coded_visibility_table
        super.merge backlogs_visibility_table
      end

      ##
      # Relies on type names in the core TypeSeeder being (in this order)
      #   task, milestone, phase, feature, epic, user_story, bug
      # and 0 to 2 being mapped to
      #   hidden, default, visible
      def backlogs_visibility_table
        {
          story_points:   [0, 0, 0, 1, 2, 2, 1],
          remaining_time: [1, 0, 0, 1, 1, 1, 1]
        }
      end
    end

    BasicData::TypeSeeder.prepend BasicData::Backlogs::TypeSeeder
  end
end
