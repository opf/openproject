class CreateProjectCustomFieldProjectMappings < ActiveRecord::Migration[7.0]
  def up
    create_table :project_custom_field_project_mappings do |t|
      t.references :custom_field, foreign_key: true, index: {
        name: "index_project_cf_project_mappings_on_custom_field_id"
      }
      t.references :project, foreign_key: true

      t.timestamps
    end

    create_default_mapping
  end

  def down
    drop_table :project_custom_field_project_mappings
  end

  private

  def create_default_mapping
    project_ids = Project.pluck(:id)
    custom_field_ids = ProjectCustomField.pluck(:id)
    mappings = []

    project_ids.each do |project_id|
      custom_field_ids.each do |custom_field_id|
        mappings << { custom_field_id:, project_id: }
      end
    end

    ProjectCustomFieldProjectMapping.create!(mappings)
  end
end
