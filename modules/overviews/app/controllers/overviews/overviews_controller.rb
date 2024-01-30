module ::Overviews
  class OverviewsController < ::Grids::BaseInProjectController
    include OpTurbo::ComponentStream

    before_action :jump_to_project_menu_item
    before_action :check_project_attributes_feature_enabled,
                  only: %i[attributes_sidebar attribute_section_dialog update_attributes]

    menu_item :overview

    def attributes_sidebar
      # TODO: check permissions
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
      # TODO: check permissions
      @section = find_project_custom_field_section

      render(
        ProjectCustomFields::Sections::EditDialogComponent.new(
          project: @project,
          project_custom_field_section: @section
        ),
        layout: false
      )
    end

    def update_attributes
      @section = find_project_custom_field_section

      # TODO: transform to contract/service-based approach with permission checks
      @project.update_custom_field_values_of_section(@section, permitted_params.project)

      has_errors = @project.errors.any?

      if has_errors
        handle_errors
      else
        update_sidebar_component
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

    def check_project_attributes_feature_enabled
      render_404 unless OpenProject::FeatureDecisions.project_attributes_active?
    end

    def active_project_custom_fields_grouped_by_section
      # TODO: move to service/model
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

    def handle_errors
      update_via_turbo_stream(
        component: ProjectCustomFields::Sections::EditDialogComponent.new(
          project: @project,
          project_custom_field_section: @section
        )
      )
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
