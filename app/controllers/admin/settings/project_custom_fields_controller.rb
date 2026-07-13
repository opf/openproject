# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin::Settings
  class ProjectCustomFieldsController < ::Admin::SettingsController
    include CustomFields::SharedActions
    include CustomFields::AttributeHelpTextActions
    include OpTurbo::ComponentStream
    include FlashMessagesOutputSafetyHelper
    include Admin::Settings::ProjectCustomFields::ComponentStreams

    menu_item :project_custom_fields_settings

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :set_sections, only: %i[show index edit update move drop]
    before_action :find_custom_field,
                  only: %i(show edit project_mappings new_link link unlink update destroy delete_option reorder_alphabetical
                           move drop role_assignment update_role_assignment role_assignment_preview_dialog
                           attribute_help_text update_attribute_help_text list_items)
    before_action :prepare_custom_option_position, only: %i(update create)
    before_action :find_custom_option, only: :delete_option
    before_action :project_custom_field_mappings_query, only: %i[project_mappings unlink]
    before_action :find_custom_field_projects_to_link, only: :link
    before_action :find_unlink_project_custom_field_mapping, only: :unlink
    before_action :prepare_role_assignment_form, only: %i[role_assignment update_role_assignment]
    before_action :find_or_initialize_attribute_help_text, only: %i[attribute_help_text update_attribute_help_text]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def index
      @allow_custom_field_creation = @project_custom_field_sections.any?

      respond_to :html
    end

    def show
      # quick fixing redirect issue from perform_update
      # perform_update is always redirecting to the show action although configured otherwise
      render :edit
    end

    def new
      @custom_field = ProjectCustomField.new(custom_field_section_id: params[:custom_field_section_id],
                                             field_format: params[:field_format])

      respond_to :html
    end

    def edit; end

    def list_items; end

    def project_mappings; end

    def role_assignment; end

    def role_assignment_preview_dialog
      role = params[:role_id].to_i == 0 ? nil : ProjectRole.find_by(id: params[:role_id])
      respond_with_dialog(Admin::CustomFields::RoleAssignmentPreviewDialogComponent.new(custom_field: @custom_field, role: role))
    end

    def update_role_assignment
      call = CustomFields::LinkWithRoleService
        .new(user: current_user, model: @custom_field)
        .call(role_assignment_params)

      call.on_success do
        flash[:notice] = t(:notice_successful_update)
        redirect_to role_assignment_admin_settings_project_custom_field_path(@custom_field)
      end

      call.on_failure do
        flash[:error] = call.message || I18n.t(:notice_internal_server_error)
        render :role_assignment
      end
    end

    def new_link
      @project_mapping = ProjectCustomFieldProjectMapping.new(project_custom_field: @custom_field)
      respond_with_dialog Settings::ProjectCustomFields::ProjectCustomFieldMapping::NewProjectMappingComponent.new(
        custom_field_project_mapping: @project_mapping,
        custom_field: @custom_field
      )
    end

    def link
      create_service = ProjectCustomFieldProjectMappings::BulkCreateService
                         .new(user: current_user, projects: @projects, model: @custom_field,
                              include_sub_projects: include_sub_projects?)
                         .call

      create_service.on_success { render_project_list(url_for_action: :project_mappings) }

      create_service.on_failure do
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(create_service.errors)
        )
      end

      respond_to_with_turbo_streams(status: create_service)
    end

    def unlink
      delete_service = ProjectCustomFieldProjectMappings::DeleteService
                         .new(user: current_user, model: @project_custom_field_mapping)
                         .call

      delete_service.on_success { render_project_list(url_for_action: :project_mappings) }

      delete_service.on_failure do
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(delete_service.errors.full_messages)
        )
      end

      respond_to_with_turbo_streams(status: delete_service)
    end

    def move
      result = CustomFields::MoveService.new(user: current_user, custom_field: @custom_field).call(
        move_to: params.expect(:move_to)
      )

      if result.success?
        update_sections_via_turbo_stream(project_custom_field_sections: @project_custom_field_sections)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def drop
      result = CustomFields::DropService.new(user: current_user, custom_field: @custom_field).call(
        target_id: params[:target_id],
        position: params[:position]
      )

      if result.success?
        drop_success_streams(result)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def destroy
      result = CustomFields::DeleteService.new(user: current_user, model: @custom_field).call

      if result.success?
        update_section_via_turbo_stream(project_custom_field_section: @custom_field.project_custom_field_section.reload)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def attribute_help_text
      render_attribute_help_text_form
    end

    def update_attribute_help_text
      update_help_text
    end

    private

    def prepare_role_assignment_form
      @custom_field_usages = @custom_field.custom_values.where.not(value: nil)
    end

    def render_project_list(url_for_action: action_name)
      update_via_turbo_stream(
        component: Settings::ProjectCustomFields::ProjectCustomFieldMapping::TableComponent.new(
          query: project_custom_field_mappings_query,
          params: params.merge({ custom_field: @custom_field, url_for_action: })
        )
      )
    end

    def project_custom_field_mappings_query
      @project_custom_field_mappings_query = ProjectQuery.new(
        name: "project-custom-field-mappings-#{@custom_field.id}"
      ) do |query|
        query.where(:available_project_attributes, "=", [@custom_field.id])
        query.select(:name)
        query.order("lft" => "asc")
      end
    end

    def set_sections
      @project_custom_field_sections = ProjectCustomFieldSection
                                         .includes(custom_fields: :project_custom_field_project_mappings)
                                         .all
    end

    def find_unlink_project_custom_field_mapping
      @project_custom_field_mapping = @custom_field.project_custom_field_project_mappings.find_by!(
        project_id: permitted_params.project_custom_field_project_mapping[:project_id]
      )
    rescue ActiveRecord::RecordNotFound
      render_error_flash_message_via_turbo_stream(message: t(:notice_file_not_found))
      render_project_list(url_for_action: :project_mappings)

      respond_with_turbo_streams
    end

    def find_custom_field_projects_to_link
      project_ids = params.to_unsafe_h[:project_custom_field_project_mapping][:project_ids]
      if project_ids.present?
        @projects = Project.find(project_ids)
      else
        project_mapping = ProjectCustomFieldProjectMapping.new(project_custom_field: @custom_field)
        project_mapping.errors.add(:project_ids, :blank)
        component = Settings::ProjectCustomFields::ProjectCustomFieldMapping::NewProjectMappingFormComponent.new(
          custom_field_project_mapping: project_mapping,
          custom_field: @custom_field
        )
        update_via_turbo_stream(component:, status: :bad_request)
        respond_with_turbo_streams
        false
      end
    rescue ActiveRecord::RecordNotFound
      render_error_flash_message_via_turbo_stream(message: t(:notice_project_not_found))
      render_project_list(url_for_action: :project_mappings)

      respond_with_turbo_streams
    end

    def find_custom_field
      @custom_field = ProjectCustomField.find(params.expect(:id))
    end

    def drop_success_streams(call)
      update_section_via_turbo_stream(project_custom_field_section: call.result[:current_section])
      if call.result[:section_changed]
        update_section_via_turbo_stream(project_custom_field_section: call.result[:old_section])
      end
    end

    def include_sub_projects?
      ActiveRecord::Type::Boolean.new.cast(params.to_unsafe_h[:project_custom_field_project_mapping][:include_sub_projects])
    end

    def role_assignment_params
      params.expect(custom_field: [:role_id])
    end

    def show_path
      attribute_help_text_admin_settings_project_custom_field_path(@custom_field)
    end

    def render_attribute_help_text_form(status: :ok)
      render "custom_fields/attribute_help_texts/show_project", status:
    end
  end
end
