# frozen_string_literal: true

class CreateTypeAllowedParentTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :type_allowed_parent_types do |t|
      t.references :type, null: false, foreign_key: { to_table: :types }, index: true
      t.references :parent_type, null: false, foreign_key: { to_table: :types }, index: true
    end

    add_index :type_allowed_parent_types, %i[type_id parent_type_id], unique: true
  end
end
