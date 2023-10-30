module ::Overviews
  class OverviewsController < ::Grids::BaseInProjectController
    include OpTurbo::ComponentStream

    before_action :jump_to_project_menu_item

    menu_item :overview

    def attributes_sidebar
      render(
        ProjectAttributes::SidebarComponent.new(
          project: @project
        ),
        layout: false
      )
    end

    def attribute_section_dialog
      render(
        ProjectAttributes::Section::EditDialogComponent.new(
          project: @project,
          custom_field_values: @project.custom_field_values
        ),
        layout: false
      )
    end

    def update_attributes
      # manual nested attributes update as the project model is not yet natively supporting it
      # needs refactoring

      modified_custom_field_values = []
      has_errors = false
      ActiveRecord::Base.transaction do
        # transaction to rollback if any of the custom field values fails to save
        project_attribute_params[:custom_field_values_attributes]&.each do |custom_value_id, attributes|
          custom_value = CustomValue.find(custom_value_id.to_i)

          custom_value.value = attributes[:value]
          unless custom_value.save
            has_errors = true
          end
          modified_custom_field_values << custom_value
        end

        project_attribute_params[:new_custom_field_values_attributes]&.each do |custom_field_id, attributes|
          custom_value = CustomValue.new(
            custom_field_id: custom_field_id.to_i,
            value: attributes[:value],
            customized_type: "Project",
            customized_id: @project.id
          )

          unless custom_value.save
            has_errors = true
          end
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

            unless custom_value.save
              has_errors = true
            end
            modified_custom_field_values << custom_value
          end
        end

        if has_errors
          update_via_turbo_stream(
            component: ProjectAttributes::Section::EditDialogComponent.new(
              project: @project,
              custom_field_values: modified_custom_field_values
            )
          )
          raise ActiveRecord::Rollback
        else
          update_via_turbo_stream(
            component: ProjectAttributes::SidebarComponent.new(
              project: @project
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
  end
end
