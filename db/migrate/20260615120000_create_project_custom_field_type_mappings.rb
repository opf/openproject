# frozen_string_literal: true

class CreateProjectCustomFieldTypeMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :project_custom_field_type_mappings do |t|
      t.references :type, null: false, foreign_key: true, index: false
      t.references :custom_field, null: false, foreign_key: true,
                                  index: { name: "index_project_cf_type_mappings_on_custom_field_id" }

      t.timestamps

      t.index %i[type_id custom_field_id],
              unique: true,
              name: "index_project_custom_field_type_mappings_unique"
    end
  end
end
