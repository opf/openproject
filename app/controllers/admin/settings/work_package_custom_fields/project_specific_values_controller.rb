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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Settings
    module WorkPackageCustomFields
      class ProjectSpecificValuesController < ::Admin::SettingsController
        include OpTurbo::ComponentStream

        menu_item :work_package_custom_fields

        before_action :find_custom_field
        before_action :require_project_specific_values, only: %i[index make_global deletion_dialog destroy]
        before_action :require_project_specific_value_restriction, only: %i[toggle enable_all disable_all]
        before_action :require_additional_project_values, only: %i[new create]
        before_action :find_project_using_custom_field
        before_action :find_own_value, only: %i[make_global deletion_dialog destroy]
        before_action :find_parent, only: %i[new create]

        helper_method :custom_field_page_title, :section_label

        def index; end

        def new
          respond_with_dialog ::Admin::CustomFields::Projects::NewValueDialogComponent.new(
            custom_field: @custom_field, project: @configured_project, parent: @parent
          )
        end

        def create
          errors = @custom_field.list? ? create_option : create_item

          if errors.empty?
            flash[:notice] = I18n.t(:notice_successful_create)
            redirect_to_index
          else
            update_via_turbo_stream(
              component: ::Admin::CustomFields::Projects::NewValueFormComponent.new(
                custom_field: @custom_field, project: @configured_project, values: new_value_params, errors:
              ),
              status: :unprocessable_entity
            )
            respond_with_turbo_streams
          end
        end

        def toggle
          call = ::CustomFields::ProjectSpecificValues::SetService
                   .new(user: current_user, model: @custom_field)
                   .call(project: @configured_project,
                         value: @custom_field.restrictable_values.find(params.expect(:id)),
                         enabled: params[:value] == "1")

          render json: {}, status: call.success? ? :ok : :unprocessable_entity
        end

        def enable_all
          update_all(::CustomFields::ProjectSpecificValues::EnableAllService)
        end

        def disable_all
          update_all(::CustomFields::ProjectSpecificValues::DisableAllService)
        end

        def make_global
          call = ::CustomFields::ProjectSpecificValues::MakeGlobalService
                   .new(user: current_user, model: @custom_field)
                   .call(project: @configured_project, value: @value)

          if call.success?
            flash[:notice] = I18n.t(:notice_successful_update)
          else
            flash[:error] = call.message
          end

          redirect_to_index
        end

        def deletion_dialog
          respond_with_dialog ::Admin::CustomFields::Projects::DeleteValueDialogComponent.new(
            custom_field: @custom_field, project: @configured_project, value: @value
          )
        end

        def destroy
          destroy_value

          flash[:notice] = I18n.t(:notice_successful_delete)
          redirect_to_index
        end

        private

        def find_custom_field
          @custom_field = WorkPackageCustomField.find(params.expect(:work_package_custom_field_id))
        end

        def require_project_specific_values
          return if @custom_field.project_specific_value_restriction.present?
          return if @custom_field.allow_additional_project_values?

          render_404
        end

        def require_project_specific_value_restriction
          render_404 if @custom_field.project_specific_value_restriction.nil?
        end

        def require_additional_project_values
          render_404 unless @custom_field.allow_additional_project_values?
        end

        # Not @project, as that would render the project menu instead of the administration menu.
        def find_project_using_custom_field
          @configured_project = Project.active
                                       .with_available_custom_fields([@custom_field.id])
                                       .find(params.expect(:project_id))
        end

        def find_own_value
          @value = @custom_field.restrictable_values
                                .where(project_id: @configured_project.id)
                                .find(params.expect(:id))
        end

        def find_parent
          return if params[:parent_id].blank?

          @parent = @custom_field.hierarchy_root
                                 .self_and_descendants
                                 .where(project_id: [nil, @configured_project.id])
                                 .find(params.expect(:parent_id))
        end

        def new_value_params
          params.permit(:label, :short, :weight, :parent_id).to_h.symbolize_keys
        end

        def create_option
          errors = ::CustomOptions::CreateService
                     .new(user: current_user)
                     .call(custom_field: @custom_field, project: @configured_project, value: params[:label])
                     .errors
                     .to_hash(true)
          errors[:label] = errors.delete(:value) if errors.key?(:value)
          errors
        end

        def create_item
          ::CustomFields::Hierarchy::HierarchicalItemService
            .new
            .insert_item(contract_class: insert_item_contract,
                         parent: @parent,
                         label: params[:label],
                         short: params[:short],
                         weight: params[:weight],
                         project: @configured_project)
            .either(->(_) { {} }, ->(validation) { item_errors(validation) })
        end

        def insert_item_contract
          if @custom_field.field_format_weighted_item_list?
            ::CustomFields::Hierarchy::InsertWeightedItemContract
          else
            ::CustomFields::Hierarchy::InsertListItemContract
          end
        end

        def item_errors(validation)
          errors = validation.errors(full: true).to_h
          errors[:parent_id] = errors.delete(:parent) if errors.key?(:parent)
          errors
        end

        def update_all(service_class)
          call = service_class.new(user: current_user, model: @custom_field).call(project: @configured_project)
          flash[:error] = call.message unless call.success?

          redirect_to_index
        end

        def destroy_value
          if @custom_field.list?
            @value.destroy!
            CustomValue.where(custom_field: @custom_field, value: @value.id).delete_all
          else
            ::CustomFields::Hierarchy::HierarchicalItemService.new.delete_branch(item: @value).value!
          end
        end

        def redirect_to_index
          redirect_to admin_settings_work_package_custom_field_project_specific_values_path(@custom_field, @configured_project),
                      status: :see_other
        end

        def custom_field_page_title
          t(:label_custom_field_plural)
        end

        def section_label
          t(:label_work_package_plural)
        end
      end
    end
  end
end
