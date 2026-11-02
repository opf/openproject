# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/utils")

class FixTmSuitesUniqueIndexNullsNotDistinct < ActiveRecord::Migration[8.0]
  include Migration::Utils

  def up
    remove_index_on :tm_suites, "index_tm_suites_on_project_parent_name", %w[project_id parent_id name]
    add_index :tm_suites, %i[project_id parent_id name],
              unique: true,
              nulls_not_distinct: true,
              name: "index_tm_suites_on_project_parent_name"
  end

  def down
    remove_index_on :tm_suites, "index_tm_suites_on_project_parent_name", %w[project_id parent_id name]
    add_index :tm_suites, %i[project_id parent_id name],
              unique: true,
              name: "index_tm_suites_on_project_parent_name"
  end
end
