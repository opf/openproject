class CreateWorkPackageJournals < ActiveRecord::Migration
  def change
    create_table :work_package_journals do |t|
      t.integer  :journal_id,                                      :null => false
      t.integer  :type_id,                         :default => 0,  :null => false
      t.integer  :project_id,                      :default => 0,  :null => false
      t.string   :subject,                         :default => "", :null => false
      t.text     :description
      t.date     :due_date
      t.integer  :category_id
      t.integer  :status_id,                       :default => 0,  :null => false
      t.integer  :assigned_to_id
      t.integer  :priority_id,                     :default => 0,  :null => false
      t.integer  :fixed_version_id
      t.integer  :author_id,                       :default => 0,  :null => false
      t.integer  :lock_version,                    :default => 0,  :null => false
      t.integer  :done_ratio,                      :default => 0,  :null => false
      t.float    :estimated_hours
      t.datetime :created_at
      t.datetime :updated_at
      t.date     :start_date
      t.text     :planning_element_status_comment
      t.datetime :deleted_at
      t.integer  :parent_id
      t.integer  :responsible_id
      t.integer  :planning_element_status_id
      t.string   :sti_type
      t.integer  :root_id
      t.integer  :lft
      t.integer  :rgt
    end
  end
end
