# frozen_string_literal: true

# Milestones (0012): a release, sprint, regression cycle, UAT phase etc. that test runs are
# assigned to. Progress rolls up from the runs of the milestone and of its sub-milestones
# (one level). Milestones link to work packages (like runs and cases do) and, optionally, to
# an OpenProject Version: every work package of that version then shows the milestone in
# its Testing tab.
class CreateTmMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_milestones do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      # Deleting a parent keeps its sub-milestones as top-level milestones.
      t.references :parent, foreign_key: { to_table: :tm_milestones, on_delete: :nullify }, index: true
      t.references :version, foreign_key: { on_delete: :nullify }, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.date :start_date
      t.date :due_date
      t.string :status, null: false, default: "open", limit: 16
      t.datetime :started_at
      t.datetime :completed_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_milestones, %i[project_id status], name: "index_tm_milestones_on_project_and_status"

    create_table :tm_milestone_work_packages do |t|
      t.references :milestone, null: false, foreign_key: { to_table: :tm_milestones, on_delete: :cascade }, index: false
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps null: false
    end
    add_index :tm_milestone_work_packages, %i[milestone_id work_package_id], unique: true,
                                                                             name: "index_tm_milestone_wps_on_milestone_and_wp"

    add_reference :tm_test_runs, :milestone, foreign_key: { to_table: :tm_milestones, on_delete: :nullify }, index: true
  end
end
