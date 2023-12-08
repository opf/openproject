module ::Overviews
  class OverviewsController < ::Grids::BaseInProjectController
    include OpTurbo::ComponentStream

    before_action :jump_to_project_menu_item

    menu_item :overview

    def attributes_sidebar
      render(
        ProjectCustomFields::SidebarComponent.new(
          project: @project,
          project_custom_field_sections: ProjectCustomFieldSection.all,
          active_project_custom_fields_grouped_by_section:
        ),
        layout: false
      )
    end

    def attribute_section_dialog
      section = ProjectCustomFieldSection.find(params[:section_id])

      eager_loaded_project_custom_field_values = CustomValue.where(
        custom_field_id: active_project_custom_fields_of_section(section.id).pluck(:id),
        customized_id: @project.id
      ).to_a

      render(
        ProjectCustomFields::Sections::EditDialogComponent.new(
          project: @project,
          project_custom_field_section: section,
          active_project_custom_fields_of_section: active_project_custom_fields_of_section(section.id),
          project_custom_field_values: eager_loaded_project_custom_field_values
        ),
        layout: false
      )
    end

    def update_attributes
      section = find_project_custom_field_section

      has_errors = false

      ActiveRecord::Base.transaction do
        modified_custom_field_values = modify_custom_field_values(section)
        modified_custom_field_values = add_missing_required_custom_values(section, modified_custom_field_values)

        has_errors = modified_custom_field_values.any?(&:invalid?)

        if has_errors
          handle_errors(section, modified_custom_field_values)
        else
          save_custom_field_values(modified_custom_field_values)
          delete_missing_custom_field_values(section, modified_custom_field_values)
          delete_unused_multi_values(unused_multi_values(section))

          update_sidebar_component
        end
      end

      respond_to_with_turbo_streams(status: has_errors ? :unprocessable_entity : :ok)
    end

    def jump_to_project_menu_item
      if params[:jump]
        # try to redirect to the requested menu item
        redirect_to_project_menu_item(@project, params[:jump]) && return
      end
    end

    private

    def project_attribute_params
      params.require(:project).permit(
        custom_field_values_attributes: [:value],
        new_custom_field_values_attributes: [:value],
        multi_user_custom_field_values_attributes: [:custom_field_id, { comma_seperated_values: [] }],
        multi_custom_field_values_attributes: [:custom_field_id, { values: [] }]
      )
    end

    def active_project_custom_fields_grouped_by_section
      # TODO: move to service
      active_custom_field_ids_of_project = ProjectCustomFieldProjectMapping
        .where(project_id: @project.id)
        .pluck(:custom_field_id)

      ProjectCustomField
        .includes(:project_custom_field_section)
        .where(id: active_custom_field_ids_of_project)
        .sort_by { |pcf| pcf.project_custom_field_section.position }
        .group_by(&:custom_field_section_id)
    end

    def active_project_custom_fields_of_section(section_id)
      active_project_custom_fields_grouped_by_section[section_id]
        .sort_by(&:position_in_custom_field_section)
    end

    def find_project_custom_field_section
      ProjectCustomFieldSection.find(params[:section_id])
    end

    def modify_custom_field_values(section)
      custom_field_values = []

      transaction_custom_field_values(section, :custom_field_values_attributes) do |custom_value_id, attributes|
        custom_value = update_custom_value(custom_value_id, attributes)
        custom_field_values << custom_value
      end

      transaction_custom_field_values(section, :new_custom_field_values_attributes) do |custom_field_id, attributes|
        custom_value = build_new_custom_value(custom_field_id, attributes)
        custom_field_values << custom_value
      end

      transaction_custom_field_values(section, :multi_custom_field_values_attributes) do |custom_field_id, attributes|
        custom_field_values.concat(update_multi_custom_field_values(custom_field_id, attributes))
      end

      transaction_custom_field_values(section, :multi_user_custom_field_values_attributes) do |custom_field_id, attributes|
        custom_field_values.concat(update_multi_user_custom_field_values(custom_field_id, attributes))
      end

      custom_field_values
    end

    def unused_multi_values(section)
      custom_field_values = []

      transaction_custom_field_values(section, :multi_custom_field_values_attributes) do |custom_field_id, attributes|
        custom_field_values.concat(detect_unused_multi_values(custom_field_id, attributes))
      end

      transaction_custom_field_values(section, :multi_user_custom_field_values_attributes) do |custom_field_id, attributes|
        custom_field_values.concat(detect_unused_user_multi_values(custom_field_id, attributes))
      end

      custom_field_values
    end

    def transaction_custom_field_values(_section, attribute_key)
      project_attribute_params[attribute_key]&.each do |custom_value_id, attributes|
        yield(custom_value_id.to_i, attributes)
      end
    end

    def update_custom_value(custom_value_id, attributes)
      custom_value = CustomValue.find(custom_value_id.to_i)
      custom_value.value = attributes[:value]
      custom_value
    end

    def build_new_custom_value(custom_field_id, attributes)
      CustomValue.new(
        custom_field_id: custom_field_id.to_i,
        value: attributes[:value],
        customized_type: "Project",
        customized_id: @project.id
      )
    end

    def update_multi_custom_field_values(custom_field_id, attributes)
      custom_field_values = []

      existing_values_to_keep = attributes[:values] || []

      existing_values_to_keep.each do |value|
        custom_value = find_or_initialize_custom_value(custom_field_id, value)
        custom_field_values << custom_value
      end

      custom_field_values
    end

    def update_multi_user_custom_field_values(custom_field_id, attributes)
      custom_field_values = []

      existing_values_to_keep = attributes[:comma_seperated_values][0]&.split(',') || []

      existing_values_to_keep.each do |value|
        custom_value = find_or_initialize_custom_value(custom_field_id, value)
        custom_field_values << custom_value
      end

      custom_field_values
    end

    def detect_unused_multi_values(custom_field_id, attributes)
      existing_values_to_keep = attributes[:values] || []
      unused_multi_values_to_be_deleted(custom_field_id, existing_values_to_keep)
    end

    def detect_unused_user_multi_values(custom_field_id, attributes)
      existing_values_to_keep = attributes[:comma_seperated_values][0]&.split(',') || []
      unused_multi_values_to_be_deleted(custom_field_id, existing_values_to_keep)
    end

    def unused_multi_values_to_be_deleted(custom_field_id, existing_values_to_keep)
      @project.custom_values
        .where(custom_field_id: custom_field_id.to_i)
        .where.not(value: existing_values_to_keep)
        .to_a
    end

    def find_or_initialize_custom_value(custom_field_id, value)
      CustomValue.find_or_initialize_by(
        custom_field_id: custom_field_id.to_i,
        value:,
        customized_type: "Project",
        customized_id: @project.id
      )
    end

    def handle_errors(section, modified_custom_field_values)
      update_via_turbo_stream(
        component: ProjectCustomFields::Sections::EditDialogComponent.new(
          project: @project,
          project_custom_field_section: section,
          active_project_custom_fields_of_section: active_project_custom_fields_of_section(section.id),
          project_custom_field_values: modified_custom_field_values
        )
      )
    end

    def save_custom_field_values(modified_custom_field_values)
      modified_custom_field_values.each(&:save!)
    end

    def handle_missing_values(section, modified_custom_field_values)
      mark_missing_values_as_required(section, modified_custom_field_values)
    end

    def get_missing_custom_field_ids(section, modified_custom_field_values)
      custom_field_ids_of_section = active_project_custom_fields_of_section(section.id).pluck(:id)
      modified_custom_field_ids = modified_custom_field_values.pluck(:custom_field_id)

      custom_field_ids_of_section - modified_custom_field_ids
    end

    def delete_missing_custom_field_values(section, modified_custom_field_values)
      missing_custom_field_ids = get_missing_custom_field_ids(section, modified_custom_field_values)

      non_required_custom_field_ids = ProjectCustomField
        .where(id: missing_custom_field_ids)
        .where.not(is_required: true)
        .pluck(:id)

      CustomValue
        .where(custom_field_id: non_required_custom_field_ids, customized_id: @project.id)
        .destroy_all
    end

    def delete_unused_multi_values(custom_values_to_be_deleted)
      custom_values_to_be_deleted.each(&:destroy!)
    end

    def add_missing_required_custom_values(section, modified_custom_field_values)
      missing_custom_field_ids = get_missing_custom_field_ids(section, modified_custom_field_values)

      required_custom_field_ids = ProjectCustomField
        .where(id: missing_custom_field_ids)
        .where(is_required: true)
        .pluck(:id)

      required_custom_field_ids.each do |custom_field_id|
        custom_value = CustomValue.find_or_initialize_by(
          custom_field_id: custom_field_id.to_i,
          customized_type: "Project",
          customized_id: @project.id
        )
        custom_value.value = nil
        custom_value.errors.add(:value, :blank)

        modified_custom_field_values << custom_value
      end

      modified_custom_field_values
    end

    def update_sidebar_component
      update_via_turbo_stream(
        component: ProjectCustomFields::SidebarComponent.new(
          project: @project,
          project_custom_field_sections: ProjectCustomFieldSection.all,
          active_project_custom_fields_grouped_by_section:
        )
      )
    end
  end
end
