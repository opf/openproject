class AddUniquenessIndexToProjectCustomFieldProjectMappings < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      DELETE FROM project_custom_field_project_mappings AS pcfpm_1
        USING project_custom_field_project_mappings AS pcfpm_2
      WHERE pcfpm_1.project_id = pcfpm_2.project_id
        AND pcfpm_1.custom_field_id = pcfpm_2.custom_field_id
        AND pcfpm_1.id > pcfpm_2.id;
    SQL

    add_index :project_custom_field_project_mappings, %i[project_id custom_field_id],
              unique: true,
              name: "index_project_custom_field_project_mappings_unique"
  end

  def down
    remove_index :project_custom_field_project_mappings, name: "index_project_custom_field_project_mappings_unique"
  end
end
