class CreateTimelinesReportings < ActiveRecord::Migration
  def self.up
    create_table(:timelines_reportings) do |t|
      t.column :reported_project_status_comment, :text

      t.belongs_to :project
      t.belongs_to :reporting_to_project
      t.belongs_to :reported_project_status

      t.timestamps
    end
    add_index :timelines_reportings, :project_id
    add_index :timelines_reportings, :reporting_to_project_id
    add_index :timelines_reportings, :reported_project_status_id
  end

  def self.down
    drop_table(:timelines_reportings)
  end
end
