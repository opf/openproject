class AddStatusColumnsToProjectJournals < ActiveRecord::Migration[7.0]
  def change
    change_table :project_journals, bulk: true do |table|
      table.integer :status_code
      table.text :status_explanation
    end
  end
end
