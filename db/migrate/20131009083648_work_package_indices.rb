class WorkPackageIndices < ActiveRecord::Migration
  def up
    # drop obsolete fields
    remove_column :work_packages, :planning_element_status_comment
    remove_column :work_packages, :planning_element_status_id
    remove_column :work_packages, :sti_type
    remove_column :work_package_journals, :planning_element_status_comment
    remove_column :work_package_journals, :planning_element_status_id
    remove_column :work_package_journals, :sti_type

    add_index :work_packages, :type_id
    add_index :work_packages, :status_id
    add_index :work_packages, :category_id

    add_index :work_packages, :author_id
    add_index :work_packages, :assigned_to_id

    add_index :work_packages, :created_at
    add_index :work_packages, :fixed_version_id

  end

  def down
    add_column :work_packages, :planning_element_status_comment, :string
    add_column :work_packages, :planning_element_status_id, :integer
    add_column :work_packages, :sti_type, :string
    add_column :work_package_journals, :planning_element_status_comment, :string
    add_column :work_package_journals, :planning_element_status_id, :integer
    add_column :work_package_journals, :sti_type, :string

    remove_index :work_packages, :type_id
    remove_index :work_packages, :status_id
    remove_index :work_packages, :category_id

    remove_index :work_packages, :author_id
    remove_index :work_packages, :assigned_to_id

    remove_index :work_packages, :created_at
    remove_index :work_packages, :fixed_version_id


  end

end
