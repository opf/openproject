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

      include ApiController
      include ::Api::Experimental::Concerns::GrapeRouting
      include ::Api::Experimental::Concerns::ColumnData
      include ::Api::Experimental::Concerns::QueryLoading
      include ::Api::Experimental::Concerns::V3Naming

      include PaginationHelper
      include QueriesHelper
      include SortHelper
      include ExtendedHTTP

      before_filter :find_optional_project,
                    :v3_params_as_internal,
                    :load_query

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

      def work_packages_links
        links = {}
        links[:create] = api_experimental_work_packages_path(@project) if User.current.allowed_to?(:add_work_packages, @project)
        links[:export] = api_experimental_work_packages_path(@project) if User.current.allowed_to?(:export_work_packages, @project, global: @project.nil?)
        links
      end

      def query_as_json(query, user)
        json_query = query.as_json(except: :filters, include: :filters, methods: [:starred])
        # prefer using the identifier throughout the frontend so that we can
        # cache the requests more efficiently
        json_query["project_id"] = @project.identifier if @project

        json_query[:_links] = allowed_links_on_query(query, user)

        json_query_as_v3(json_query)
      end

      def export_formats
        [
          { identifier: 'atom', format: 'atom', label_locale: 'label_format_atom' },
          { identifier: 'pdf',  format: 'pdf', label_locale: 'label_format_pdf' },
          {
            identifier: 'pdf-descr',  format: 'pdf',
            label_locale: 'label_format_pdf_with_descriptions', flags: ['show_descriptions']
          },
          { identifier: 'csv', format: 'csv', label_locale: 'label_format_csv' }
        ]
      end
    end
  end
end
