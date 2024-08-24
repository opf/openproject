class EnableRequiredProjectCustomFieldsInAllProjects < ActiveRecord::Migration[7.1]
  def up
    required_custom_field_ids = ProjectCustomField.required.ids

    # Gather the custom_field_ids for every project, then add a new mapping
    # of {project_id:, custom_field_id:} for every project that does not have
    # the required required_custom_field_ids activated.
    missing_custom_field_attributes =
      Project
        .includes(:project_custom_field_project_mappings)
        .pluck(:id, "project_custom_field_project_mappings.custom_field_id")
        .group_by(&:first)
        .transform_values { |values| values.map(&:last) }
        .reduce([]) do |acc, (project_id, custom_field_ids)|
          missing_custom_field_ids = required_custom_field_ids - custom_field_ids

          acc + missing_custom_field_ids.map do |custom_field_id|
            { project_id:, custom_field_id: }
          end
        end

    ProjectCustomFieldProjectMapping.insert_all!(missing_custom_field_attributes)
  end

  def down
    # reversing this migration is not possible as we don't store the original state
  end
end
