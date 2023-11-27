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

      active_project_custom_fields_of_section = active_project_custom_fields_grouped_by_section[section.id]
        .sort_by(&:position_in_custom_field_section)

      eager_loaded_project_custom_field_values = CustomValue.where(
        custom_field_id: active_project_custom_fields_of_section.pluck(:id),
        customized_id: @project.id
      ).to_a

      render(
        ProjectCustomFields::Sections::EditDialogComponent.new(
          project: @project,
          project_custom_field_section: section,
          active_project_custom_fields_of_section:,
          project_custom_field_values: eager_loaded_project_custom_field_values
        ),
        layout: false
      )
    end

    def update_attributes
      # prototypical implementation
      # manual nested attributes update as the project model is not yet natively supporting it
      # needs refactoring

      section = ProjectCustomFieldSection.find(params[:section_id])

      active_project_custom_fields_of_section = active_project_custom_fields_grouped_by_section[section.id]
        .sort_by(&:position_in_custom_field_section)

      modified_custom_field_values = []

      has_errors = false

      ActiveRecord::Base.transaction do
        # transaction to rollback if any of the custom field values fails to save
        project_attribute_params[:custom_field_values_attributes]&.each do |custom_value_id, attributes|
          custom_value = CustomValue.find(custom_value_id.to_i)

          custom_value.value = attributes[:value]
          has_errors = true if custom_value.invalid?
          modified_custom_field_values << custom_value
        end

        project_attribute_params[:new_custom_field_values_attributes]&.each do |custom_field_id, attributes|
          custom_value = CustomValue.new(
            custom_field_id: custom_field_id.to_i,
            value: attributes[:value],
            customized_type: "Project",
            customized_id: @project.id
          )

          has_errors = true if custom_value.invalid?
          modified_custom_field_values << custom_value
        end

        # TODO: Cannot detect if all values are removed from a multi value custom field
        # autocompleter does not send '_blank' as value when no option is selected as configured
        project_attribute_params[:multi_custom_field_values_attributes]&.each do |custom_field_id, attributes|
          # Detect removed values
          @project.custom_values
            .where(custom_field_id: custom_field_id.to_i)
            .where.not(value: attributes[:values])
            .destroy_all

          attributes[:values]&.each do |value|
            custom_value = CustomValue.find_or_initialize_by(
              custom_field_id: custom_field_id.to_i,
              value:,
              customized_type: "Project",
              customized_id: @project.id
            )

            has_errors = true if custom_value.invalid?
            modified_custom_field_values << custom_value
          end
        end

        if has_errors
          update_via_turbo_stream(
            component: ProjectCustomFields::Sections::EditDialogComponent.new(
              project: @project,
              project_custom_field_section: section,
              active_project_custom_fields_of_section:,
              project_custom_field_values: modified_custom_field_values
            )
          )
        else
          modified_custom_field_values.each(&:save!)
          update_via_turbo_stream(
            component: ProjectCustomFields::SidebarComponent.new(
              project: @project,
              project_custom_field_sections: ProjectCustomFieldSection.all,
              active_project_custom_fields_grouped_by_section:
            )
          )
        end
      end

      respond_with_turbo_streams
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
  end
end
