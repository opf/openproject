# frozen_string_literal: true

# Configuration groups and values (TestRail-style matrices), managed in
# Project settings → Test management. Optional on standalone runs and on plan entries.
class CreateTmConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_configuration_groups do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.timestamps null: false
    end
    add_index :tm_configuration_groups, %i[project_id name], unique: true,
                                                             name: "index_tm_configuration_groups_on_project_and_name"

    create_table :tm_configurations do |t|
      t.references :configuration_group,
                   null: false,
                   foreign_key: { to_table: :tm_configuration_groups, on_delete: :cascade },
                   index: true
      t.string :name, null: false, limit: 255
      t.timestamps null: false
    end
    add_index :tm_configurations, %i[configuration_group_id name], unique: true,
                                                                   name: "index_tm_configurations_on_group_and_name"
  end
end
