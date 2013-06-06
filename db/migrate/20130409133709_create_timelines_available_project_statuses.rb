class CreateTimelinesAvailableProjectStatuses < ActiveRecord::Migration
  def self.up
    create_table(:timelines_available_project_statuses) do |t|
      t.belongs_to :project_type
      t.belongs_to :reported_project_status

      t.timestamps
    end

    add_index :timelines_available_project_statuses, :project_type_id
    add_index :timelines_available_project_statuses, :reported_project_status_id, :name => "index_timelines_avail_project_statuses_on_rep_project_status_id"
  end

  def self.down
    drop_table(:timelines_available_project_statuses)
  end
end
