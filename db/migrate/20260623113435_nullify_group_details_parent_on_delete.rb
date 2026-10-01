# frozen_string_literal: true

class NullifyGroupDetailsParentOnDelete < ActiveRecord::Migration[8.1]
  # Deleting a department that is the parent of another one used to fail because the
  # group_details.parent_id foreign key restricted it. Nullify children's parent instead, so the
  # children become top-level departments.
  def up
    remove_foreign_key :group_details, column: :parent_id
    add_foreign_key :group_details, :users, column: :parent_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :group_details, column: :parent_id
    add_foreign_key :group_details, :users, column: :parent_id
  end
end
