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

module WorkPackageTypes
  module ProjectsTab
    module TableRefresh
      extend ActiveSupport::Concern
      include PaginationHelper

      VARIANT_FILTER_KEY = ::Queries::Projects::Filters::TypeVariantFilter.key.to_s
      NAME_FILTER_KEY = ::Queries::Projects::Filters::NameAndIdentifierFilter.key.to_s

      included do
        helper_method :projects_table_component, :sub_header_component
      end

      private

      def load_query
        @query = ProjectQuery.new(name: "work-package-type-variant-projects-#{@variant.id}") do |query|
          query.where(:type_variant_id, "=", filtered_variant_ids)
          query.where(:name_and_identifier, "~", [project_name_term]) if project_name_term.present?
          query.order("lft" => "asc")
        end
      end

      # The text input and the variant panel both write the one `filters` param, which is what lets
      # them narrow the table together rather than overwriting each other.

      def project_name_term
        @project_name_term ||= values_for(NAME_FILTER_KEY).first.to_s.strip
      end

      def filtered_variant_ids
        (requested_variant_ids & own_variant_ids).presence || default_variant_ids
      end

      def default_variant_ids
        params[:variant_id].present? ? [@variant.id.to_s] : own_variant_ids
      end

      def own_variant_ids
        @own_variant_ids ||= @type.variants.pluck(:id).map(&:to_s)
      end

      def requested_variant_ids = values_for(VARIANT_FILTER_KEY)

      def values_for(filter_key)
        requested_filters
          .select { |filter| filter[:attribute].to_s == filter_key }
          .flat_map { |filter| Array(filter[:values]).map(&:to_s) }
      end

      # Parsed by the app's own parser rather than by hand: the filter form writes
      # `name ~ "term"` by default and only switches to JSON when told to, and both reach here.
      def requested_filters
        return @requested_filters if defined?(@requested_filters)

        @requested_filters = params[:filters].blank? ? [] : Array(::Queries::ParamsParser.parse(params)[:filters])
      rescue StandardError
        @requested_filters = []
      end

      def refresh_projects
        update_via_turbo_stream(component: projects_table_component)
        replace_via_turbo_stream(component: sub_header_component)
      end

      # Built in one place so the first render and every stream that replaces it cannot drift.
      def sub_header_component
        ProjectsTab::SubHeaderComponent.new(type: @type, variant: @variant, query: @query)
      end

      def projects_table_component
        ProjectsTab::TableComponent.new(rows: paginated_projects, variant: @variant, filtered: requested_filters.any?)
      end

      def paginated_projects
        @query.results
              .includes(project_types: :variant)
              .paginate(page: page_param, per_page: per_page_param)
      end
    end
  end
end
