class AddProjectStatusReporting < ActiveRecord::Migration[6.0]
  def change
    create_table :project_statuses do |table|
      table.references :project, null: false, foreign_key: true, index: { unique: true }
      table.text :explanation
      table.integer :code
      table.timestamps
    end
  end
end
