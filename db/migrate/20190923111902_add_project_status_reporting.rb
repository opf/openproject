class AddProjectStatusReporting < ActiveRecord::Migration[6.0]
  def change
    create_table :project_statuses do |table|
      table.references :project, null: false, foreign_key: true, index: { unique: true }
      table.text :explanation
      table.integer :code
      table.timestamps
    end

    reversible do |change|
      change.up do
        project_status_for_existing_projects
      end
    end
  end

  def project_status_for_existing_projects
    insert_sql = <<-SQL
      INSERT into project_statuses
      SELECT id AS project_id, #{Project::Status.codes['on_track']} as code FROM projects
    SQL

    insert Arel.sql(insert_sql)
  end
end
