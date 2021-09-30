class AddBcfCommentHierarchy < ActiveRecord::Migration[6.1]
  def change
    add_column :bcf_comments, :reply_to, :bigint, default: nil, null: true
    add_foreign_key :bcf_comments, :bcf_comments, column: :reply_to, on_delete: :nullify
  end
end
