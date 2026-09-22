# frozen_string_literal: true

class CreateLegacyCustomOptionMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :legacy_custom_option_mappings, id: false do |t|
      t.bigint :custom_option_id, null: false, primary_key: true
      t.bigint :hierarchical_item_id, null: false
      t.bigint :custom_field_id, null: false
    end

    add_foreign_key :legacy_custom_option_mappings, :hierarchical_items, on_delete: :cascade
    add_foreign_key :legacy_custom_option_mappings, :custom_fields, on_delete: :cascade
    add_index :legacy_custom_option_mappings, %i[custom_field_id custom_option_id]
  end
end
