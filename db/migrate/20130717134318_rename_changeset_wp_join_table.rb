class RenameChangesetWpJoinTable < ActiveRecord::Migration
  def up
    remove_index :changesets_issues, :name => :changesets_issues_ids

    rename_table :changesets_issues, :changesets_work_packages
    rename_column :changesets_work_packages, :issue_id, :work_package_id

    add_index :changesets_work_packages,
              [:changeset_id, :work_package_id],
              :unique => true,
              :name => :changesets_work_packages_ids
  end

  def down
    remove_index :changesets_work_packages, :name => :changesets_work_packages_ids

    rename_table :changesets_work_packages, :changesets_issues
    rename_column :changesets_issues, :work_package_id, :issue_id

    add_index :changesets_issues,
              [:changeset_id, :issue_id],
              :unique => true,
              :name => :changesets_issues_ids
  end
end
