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
        @display_meta = true
        @work_packages_meta_data = {
          query:                        query_as_json(@query, User.current),
          columns:                      get_columns_for_json(@query.columns),
          groupable_columns:            get_columns_for_json(@query.groupable_columns),
          page:                         page_param,
          per_page:                     per_page_param,
          per_page_options:             Setting.per_page_options_array,
          export_formats:               export_formats,
          _links:                       work_packages_links
        }
      end

      private

      def load_query
        @query ||= init_query
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def initialize_sort
        # The session contains the previous sort criteria.
        # For the WP#index, this behaviour is not supported by the frontend, therefore
        # we remove the session stored sort criteria and only take what is provided.
        sort_clear
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)
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
