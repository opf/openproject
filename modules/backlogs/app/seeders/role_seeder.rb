module BasicData
  module Backlogs
    module RoleSeeder
      def member
        super.tap do |member|
          member[:permissions].concat %i(
            view_master_backlog
            view_taskboards
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
