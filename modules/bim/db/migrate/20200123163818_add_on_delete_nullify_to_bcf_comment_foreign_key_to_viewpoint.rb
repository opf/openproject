class AddOnDeleteNullifyToBcfCommentForeignKeyToViewpoint < ActiveRecord::Migration[6.0]
  def change
    remove_reference :bcf_comments, :viewpoint
    add_reference :bcf_comments, :viewpoint, foreign_key: { to_table: :bcf_viewpoints, on_delete: :nullify }, index: true
  end
end
