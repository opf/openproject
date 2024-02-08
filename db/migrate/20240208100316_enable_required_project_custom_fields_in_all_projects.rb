class EnableRequiredProjectCustomFieldsInAllProjects < ActiveRecord::Migration[7.1]
  def up
    required_project_custom_fields = ProjectCustomField.required.find_each.to_a

    Project.includes(:project_custom_field_project_mappings).find_each do |project|
      required_project_custom_fields.each do |pcf|
        if project.project_custom_field_project_mappings.pluck(:custom_field_id).exclude?(pcf.id)
          ProjectCustomFieldProjectMapping.create!(project_id: project.id, custom_field_id: pcf.id)
        end
      end
    end
  end

  def down
    # reversing this migration is not possible as we don't store the original state
  end
end
