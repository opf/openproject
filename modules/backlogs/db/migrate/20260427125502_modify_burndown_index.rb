# frozen_string_literal: true

class ModifyBurndownIndex < ActiveRecord::Migration[8.1]
  INDEX_NAME = "work_package_journal_on_burndown_attributes"

  def up
    remove_and_add_burndown_index :sprint_id
  end

  def down
    remove_and_add_burndown_index :version_id
  end

  private

  def remove_and_add_burndown_index(column)
    remove_index(:work_package_journals, name: INDEX_NAME) if index_exists?(:work_package_journals, name: INDEX_NAME)

    add_index :work_package_journals,
              [column,
               :status_id,
               :project_id,
               :type_id],
              name: INDEX_NAME
  end
end
