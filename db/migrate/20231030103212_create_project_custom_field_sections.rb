class CreateProjectCustomFieldSections < ActiveRecord::Migration[7.0]
  def up
    create_table :project_custom_field_sections do |t|
      t.integer :position
      t.string :name

      t.timestamps
    end

    # don't pollute the custom_fields table with a section_id column which is only used by ProjectCustomFields
    # use a separate mapping table instead
    create_table :project_custom_field_section_mappings do |t|
      t.references :project_custom_field_section, foreign_key: true, index: {
        name: 'index_project_cfs_mappings_on_section_id'
      }
      t.references :custom_field, foreign_key: true
      t.integer :position

      t.timestamps
    end

    # Add a unique constraint to ensure that a custom_field can only be added to one section
    add_index :project_custom_field_section_mappings, :custom_field_id, unique: true,
                                                                        name: 'index_project_cfs_mappings_on_custom_field_id'

    create_and_assign_default_section
  end

  def down
    drop_table :project_custom_field_section_mappings
    drop_table :project_custom_field_sections
  end

  private

  def create_and_assign_default_section
    section = ProjectCustomFieldSection.create!(
      name: "Project attributes"
    )

    mappings = ProjectCustomField.pluck(:id).map do |id|
      { project_custom_field_section_id: section.id, custom_field_id: id }
    end

    ProjectCustomFieldSectionMapping.create!(mappings)
  end
end
