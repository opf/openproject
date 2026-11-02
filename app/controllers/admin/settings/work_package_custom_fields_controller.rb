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
    class WorkPackageCustomFieldsController < CustomFieldsBaseController
      include PaginationHelper

      menu_item :work_package_custom_fields

      PROJECT_VALUES_ACTIONS = %i[project_values toggle_project_value enable_all_project_values
                                  disable_all_project_values].freeze

      # Redeclaring :find_custom_field by name would drop the base controller's callback for its own actions.
      before_action(only: [:projects, :forms, :types_and_variants, *PROJECT_VALUES_ACTIONS]) { find_custom_field }
      before_action :require_project_specific_values, only: PROJECT_VALUES_ACTIONS
      before_action :find_project_using_custom_field, only: PROJECT_VALUES_ACTIONS

      def index
        super

        @project_counts = WorkPackageCustomField.project_counts
      end

      def projects
        @query = projects_query
        @filtered = @query.find_active_filter(:name_and_identifier).present? ||
                    @query.find_active_filter(:project_specific_values).present?
        @type_ids_by_project_id = @custom_field.type_ids_by_project_id
        @projects = @query.results.paginate(page: page_param, per_page: per_page_param)

        render layout: false if turbo_frame_request?
      end

      def project_values; end

      def toggle_project_value
        call = ::CustomFields::ProjectSpecificValues::SetService
                 .new(user: current_user, model: @custom_field)
                 .call(project: @configured_project,
                       value: @custom_field.restrictable_values.find(params.expect(:value_id)),
                       enabled: params[:value] == "1")

        render json: {}, status: call.success? ? :ok : :unprocessable_entity
      end

      def enable_all_project_values
        update_all_project_values(::CustomFields::ProjectSpecificValues::EnableAllService)
      end

      def disable_all_project_values
        update_all_project_values(::CustomFields::ProjectSpecificValues::DisableAllService)
      end

      def forms
        @query = forms_query
        @forms = @query.results.page(page_param).per_page(per_page_param)

        respond_to do |format|
          format.html
          format.turbo_stream do
            update_via_turbo_stream(component: forms_results_component)
            respond_with_turbo_streams
          end
        end
      end

      def types_and_variants
        @query = types_and_variants_query
        @variants = @query.results
                          .includes(:type, :form_configuration, :project)
                          .page(page_param)
                          .per_page(per_page_param)

        respond_to do |format|
          format.html
          format.turbo_stream do
            update_via_turbo_stream(component: types_and_variants_results_component)
            respond_with_turbo_streams
          end
        end
      end

      protected

      def require_project_specific_values
        render_404 if @custom_field.project_specific_value_restriction.nil?
      end

      # Not @project, as that would render the project menu instead of the administration menu.
      def find_project_using_custom_field
        @configured_project = Project.active
                                     .with_available_custom_fields([@custom_field.id])
                                     .find(params.expect(:project_id))
      end

      def projects_query
        ParamsToQueryService
          .new(Project, current_user, query_class: ProjectQuery)
          .call(params)
          .where(:active, "=", OpenProject::Database::DB_VALUE_TRUE)
          .where(:available_custom_fields_projects, "=", [@custom_field.id.to_s])
          .order(name: :asc)
      end

      def update_all_project_values(service_class)
        call = service_class.new(user: current_user, model: @custom_field).call(project: @configured_project)
        flash[:error] = call.message unless call.success?

        redirect_to project_values_admin_settings_work_package_custom_field_path(@custom_field, @configured_project),
                    status: :see_other
      end

      def forms_query
        ParamsToQueryService
          .new(FormConfiguration, current_user, query_class: ::Queries::FormConfigurations::FormConfigurationQuery)
          .call(params)
          .where(:custom_field_id, "=", [@custom_field.id])
      end

      def forms_results_component
        Admin::CustomFields::Forms::ListComponent.new(forms: @forms, filtered: name_filtered?)
      end
      helper_method :forms_results_component

      def types_and_variants_query
        ParamsToQueryService
          .new(TypeVariant, current_user, query_class: ::Queries::TypeVariants::TypeVariantQuery)
          .call(params)
          .where(:custom_field_id, "=", [@custom_field.id])
      end

      def types_and_variants_results_component
        Admin::CustomFields::TypesAndVariants::TableComponent.new(rows: @variants, filtered: name_filtered?)
      end
      helper_method :types_and_variants_results_component

      def name_filtered?
        @query.find_active_filter(:name).present?
      end

      def custom_field_class
        WorkPackageCustomField
      end

      def custom_field_scope
        WorkPackageCustomField.includes(type_variants: :type).all
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
