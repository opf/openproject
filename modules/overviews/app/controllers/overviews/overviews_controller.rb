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
      section = find_project_custom_field_section

      service_call = ::Projects::UpdateService
                      .new(
                        user: current_user,
                        model: @project
                      )
                      .call(
                        permitted_params.project.merge(
                          touched_custom_field_section_id: section.id
                        )
                      )

      if service_call.success?
        update_sidebar_component
      else
        handle_errors(service_call.result, section)
      end

      respond_to_with_turbo_streams(status: service_call.success? ? :ok : :unprocessable_entity)
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

    def handle_errors(project_with_errors, section)
      update_via_turbo_stream(
        component: ProjectCustomFields::Sections::EditDialogComponent.new(
          project: project_with_errors,
          project_custom_field_section: section
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
