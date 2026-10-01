# frozen_string_literal: true

class RepositionWorkPackages < ActiveRecord::Migration[8.1]
  def change
    reversible do |direction|
      direction.up do
        # Used to be copied 1:1 from modules/backlogs/app/services/work_packages/rebuild_positions_service.rb.
        # In the meantime, the implementation of the service changed to accommodate backlog buckets.
        # But those did not exist at the time this migration represents.
        execute <<~SQL.squish
          UPDATE work_packages
          SET position = mapping.new_position
          FROM (
            SELECT
              id,
              ROW_NUMBER() OVER (
                PARTITION BY project_id, sprint_id
                ORDER BY position, created_at
              ) AS new_position
            FROM work_packages
          ) AS mapping
          WHERE work_packages.id = mapping.id
        SQL
      end
    end
  end
end
