#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module Experimental
    class WorkPackagesController < ApplicationController
      unloadable

      DEFAULT_SORT_ORDER = ['parent', 'desc']

      include ApiController
      include ::Api::Experimental::Concerns::GrapeRouting
      include ::Api::Experimental::Concerns::ColumnData
      include ::Api::Experimental::Concerns::QueryLoading

      include PaginationHelper
      include QueriesHelper
      include SortHelper
      include ExtendedHTTP

      before_filter :find_optional_project
      before_filter :load_query, only: [:index,
                                        :column_sums]

      def index
        @work_packages = current_work_packages

        columns = all_query_columns(@query)

        @column_names, @custom_field_column_ids = separate_columns_by_custom_fields(columns)

        setup_context_menu_actions

        @work_packages = ::API::Experimental::WorkPackageDecorator.decorate(@work_packages)
      end

      def column_data
        column_names = valid_columns(params[:column_names] || [])
        raise 'API Error: No column names' if column_names.empty?
        raise 'API Error: No IDs' unless params[:ids]
        ids = params[:ids].map(&:to_i)

        work_packages = work_packages_of_ids(ids, column_names)
        work_packages = ::API::Experimental::WorkPackageDecorator.decorate(work_packages)

        @columns_data = fetch_columns_data(column_names, work_packages)
        @columns_meta = {
          total_sums: columns_total_sums(column_names, work_packages),
          group_sums: columns_group_sums(column_names, work_packages, params[:group_by])
        }
      end

      def column_sums
        column_names = valid_columns(params[:column_names] || [])
        raise 'API Error' if column_names.empty?

        work_packages = work_packages_of_query(@query, column_names)
        work_packages = ::API::Experimental::WorkPackageDecorator.decorate(work_packages)
        @column_sums = columns_total_sums(column_names, work_packages)
      end

      private

      def setup_context_menu_actions
        @can = WorkPackagePolicy.new(User.current)
      end

      def load_query
        @query ||= init_query
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def current_work_packages
        initialize_sort

        results = @query.results include: includes_for_columns(all_query_columns(@query)),
                                 order: sort_clause

        work_packages = results.work_packages
                        .page(page_param)
                        .per_page(per_page_param)
                        .changed_since(@since)
                        .all
        set_work_packages_meta_data(@query, results, work_packages)

        work_packages
      end

      def initialize_sort
        # The session contains the previous sort criteria.
        # For the WP#index, this behaviour is not supported by the frontend, therefore
        # we remove the session stored sort criteria and only take what is provided.
        sort_clear
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)
      end

      def all_query_columns(query)
        columns = query.columns.map(&:name) + [:id]

        columns << query.group_by.to_sym if query.group_by
        columns += query.sort_criteria.map { |x| x.first.to_sym }

        columns
      end

      def work_packages_of_ids(ids, column_names)
        scope = WorkPackage.visible.includes(includes_for_columns(column_names))

        Array.wrap(scope.find(*ids)).sort_by { |wp| ids.index wp.id }
      end

      def work_packages_of_query(query, column_names)
        # Note: Do not apply pagination. Used to obtain total query meta data.
        results = query.results include: includes_for_columns(column_names)

        results.work_packages.all
      end

      def set_work_packages_meta_data(query, results, work_packages)
        @display_meta = true
        @work_packages_meta_data = {
          query:                        query_as_json(query, User.current),
          columns:                      get_columns_for_json(query.columns),
          groupable_columns:            get_columns_for_json(query.groupable_columns),
          work_package_count_by_group:  results.work_package_count_by_group,
          sums:                         query.columns.map { |column| results.total_sum_of(column) },
          group_sums:                   query.group_by_column && query.columns.map { |column| results.grouped_sums(column) },
          page:                         page_param,
          per_page:                     per_page_param,
          per_page_options:             Setting.per_page_options_array,
          total_entries:                work_packages.total_entries,
          export_formats:               export_formats,
          _links:                       work_packages_links
        }
      end

      def work_packages_links
        links = {}
        links[:create] = api_experimental_work_packages_path(@project) if User.current.allowed_to?(:add_work_packages, @project)
        links[:export] = api_experimental_work_packages_path(@project) if User.current.allowed_to?(:export_work_packages, @project, global: @project.nil?)
        links
      end

      def query_as_json(query, user)
        json_query = query.as_json(except: :filters, include: :filters, methods: [:starred])

        json_query[:_links] = allowed_links_on_query(query, user)
        json_query
      end

      def export_formats
        export_formats = [{ identifier: 'atom', format: 'atom', label_locale: 'label_format_atom' },
                          { identifier: 'pdf',  format: 'pdf', label_locale: 'label_format_pdf' },
                          { identifier: 'pdf-descr',  format: 'pdf', label_locale: 'label_format_pdf_with_descriptions', flags: ['show_descriptions'] },
                          { identifier: 'csv', format: 'csv', label_locale: 'label_format_csv' }]
        # TODO: This does not belong here and should be replaced by a hook that
        #       aggregates possible formats from the plug-ins.
        if Redmine::Plugin.all.sort.map(&:id).include?(:openproject_xls_export)
          export_formats.push(identifier: 'xls', format: 'xls', label_locale: 'label_format_xls')
          export_formats.push(identifier: 'xls-descr', format: 'xls', label_locale: 'label_format_xls_with_descriptions', flags: ['show_descriptions'])
        end
        export_formats
      end

      # TODO RS: Taken from work_packages_controller, not dry - move to application controller.
      def per_page_param
        case params[:format]
        when 'csv', 'pdf'
          Setting.work_packages_export_limit.to_i
        when 'atom'
          Setting.feeds_limit.to_i
        else
          super
        end
      end
    end
  end
end
