class AddProjectStatusReporting < ActiveRecord::Migration[6.0]
  def change
    create_table :project_statuses do |table|
      table.references :project, foreign_key: true, index: { unique: true }
      table.text :description
      table.integer :code
    end
  end
end
