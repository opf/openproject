# frozen_string_literal: true

class CascadeDeleteWorkPackageSemanticAliases < ActiveRecord::Migration[8.1]
  # Deleting a project cascades to its work_packages at the database level
  # (work_packages.project_id has ON DELETE CASCADE). That database-level cascade
  # bypasses the ActiveRecord `dependent: :delete_all` on the semantic_aliases
  # association, so the restricting foreign key from work_package_semantic_aliases
  # to work_packages blocked the delete. Cascade the aliases too.
  def up
    remove_foreign_key :work_package_semantic_aliases, :work_packages
    add_foreign_key :work_package_semantic_aliases, :work_packages, on_delete: :cascade
  end

  def down
    remove_foreign_key :work_package_semantic_aliases, :work_packages
    add_foreign_key :work_package_semantic_aliases, :work_packages
  end
end
