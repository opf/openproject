# frozen_string_literal: true

class AddSemanticKeyToCustomFields < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_fields, :semantic_key, :string, null: true
    add_index :custom_fields,
              %i[type semantic_key],
              unique: true,
              where: "semantic_key IS NOT NULL",
              name: "index_custom_fields_on_type_and_semantic_key"
  end
end
