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

      # Redeclaring :find_custom_field by name would drop the base controller's callback for its own actions.
      before_action(only: %i[projects forms types_and_variants]) { find_custom_field }

      def index
        super

        @project_counts = WorkPackageCustomField.project_counts
        @form_counts = WorkPackageCustomField.form_counts
      end

      def projects
        @query = projects_query
        @filtered = @query.find_active_filter(:name_and_identifier).present? ||
                    @query.find_active_filter(:project_specific_values).present?
        @type_ids_by_project_id = @custom_field.type_ids_by_project_id
        @projects = @query.results.paginate(page: page_param, per_page: per_page_param)

        render layout: false if turbo_frame_request?
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

      def projects_query
        ParamsToQueryService
          .new(Project, current_user, query_class: ProjectQuery)
          .call(params)
          .where(:active, "=", OpenProject::Database::DB_VALUE_TRUE)
          .where(:available_custom_fields_projects, "=", [@custom_field.id.to_s])
          .order(name: :asc)
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
