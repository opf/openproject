module BasicData
  module Boards
    module RoleSeeder
      def member
        super.tap do |member|
          member[:permissions].concat %i(
            show_board_views
            manage_board_views
          )
        end
      end

      def reader
        super.tap do |reader|
          reader[:permissions].concat %i(
            show_board_views
          )
        end
      end
    end

    BasicData::RoleSeeder.prepend BasicData::Boards::RoleSeeder
  end
end
