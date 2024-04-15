class CreateCustomFieldSections < ActiveRecord::Migration[7.0]
  def up
    create_table :custom_field_sections do |t|
      t.integer :position
      t.string :name
      t.string :type # project or nil (-> work_package)

      t.timestamps
    end

    add_reference :custom_fields, :custom_field_section
    add_column :custom_fields, :position_in_custom_field_section, :integer, null: true

    create_and_assign_default_section
  end

  def down
    remove_reference :custom_fields, :custom_field_section
    remove_column :custom_fields, :position_in_custom_field_section
    drop_table :custom_field_sections
  end

  private

  def create_and_assign_default_section
    # for project custom fields only
    section = ProjectCustomFieldSection.create!(
      name: "Project attributes"
    )

    # trigger acts_as_list callbacks via updating each record instead of bulk update
    ProjectCustomField.find_each do |project_custom_field|
      project_custom_field.update!(custom_field_section_id: section.id)
    end
  end
end
