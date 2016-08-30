module BasicData
  module Backlogs
    module RoleSeeder
      def member
        super.tap do |member|
          member[:permissions].concat %i(
            view_master_backlog
            view_taskboards
            create_stories
            update_stories
            create_tasks
            update_tasks
            create_impediments
            update_impediments
          )
        end
      end

      def reader
        super.tap do |reader|
          reader[:permissions].concat %i(
            view_master_backlog
            view_taskboards
          )
        end
      end
    end

    BasicData::RoleSeeder.prepend BasicData::Backlogs::RoleSeeder
  end
end
