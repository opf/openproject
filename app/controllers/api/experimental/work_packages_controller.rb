#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
        @work_packages = current_work_packages(@project)
        @custom_field_column_names = @query.columns.select { |c| c.name.to_s =~ /cf_(.*)/ }.map(&:name)
        @column_names = [:id] | @query.columns.map(&:name) - @custom_field_column_names
        if !@query.group_by.blank?
          if @query.group_by =~ /cf_(.*)/
            @custom_field_column_names << @query.group_by
          else
            @column_names << @query.group_by.to_sym
          end
        end

        setup_context_menu_actions

        respond_to do |format|
          format.api
        end
      end

      def column_data
        raise 'API Error: No IDs' unless params[:ids]
        raise 'API Error: No column names' unless params[:column_names]

        column_names = params[:column_names]
        ids = params[:ids].map(&:to_i)
        work_packages = Array.wrap(WorkPackage.visible.find(*ids)).sort { |a, b| ids.index(a.id) <=> ids.index(b.id) }

        @columns_data = fetch_columns_data(column_names, work_packages)
        @columns_meta = {
          total_sums: columns_total_sums(column_names, work_packages),
          group_sums: columns_group_sums(column_names, work_packages, params[:group_by])
        }
      end

      def column_sums
        raise 'API Error' unless params[:column_names]

        column_names = params[:column_names]
        @column_sums = columns_total_sums(column_names, all_query_work_packages)
      end

      private

      def setup_context_menu_actions
        @can = WorkPackagePolicy.new(User.current)
      end

      def columns_total_sums(column_names, work_packages)
        column_names.map do |column_name|
          column_sum(column_name, work_packages)
        end
      end

      def column_sum(column_name, work_packages)
        fetch_column_data(column_name, work_packages, false).map { |c| c.nil? ? 0 : c }.compact.sum if column_should_be_summed_up?(column_name)
      end

      def columns_group_sums(column_names, work_packages, group_by)
        # NOTE RS: This is basically the grouped_sums method from sums.rb but we have no query to play with here
        return unless group_by
        column_names.map do |column_name|
          work_packages.map { |wp| wp.send(group_by) }
            .uniq
            .inject({}) do |group_sums, current_group|
              work_packages_in_current_group = work_packages.select { |wp| wp.send(group_by) == current_group }
              group_sums.merge current_group => column_sum(column_name, work_packages_in_current_group)
            end
        end
      end

      def load_query
        @query ||= init_query
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def current_work_packages(_projects)
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        results = @query.results include: [:assigned_to, :type, :priority, :category, :fixed_version],
                                 order: sort_clause

        work_packages = results.work_packages
                        .page(page_param)
                        .per_page(per_page_param)
                        .changed_since(@since)
                        .all
        set_work_packages_meta_data(@query, results, work_packages)

        work_packages
      end

      def all_query_work_packages
        # Note: Do not apply pagination. Used to obtain total query meta data.
        results = @query.results include: [:assigned_to, :type, :priority, :category, :fixed_version]
        work_packages = results.work_packages.all
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

      def fetch_columns_data(column_names, work_packages)
        column_names.map do |column_name|
          fetch_column_data(column_name, work_packages)
        end
      end

      def fetch_column_data(column_name, work_packages, display = true)
        if column_name =~ /cf_(.*)/
          custom_field = CustomField.find($1)
          work_packages.map do |work_package|
            custom_value = work_package.custom_values.find_by_custom_field_id($1)
            if display
              work_package.get_cast_custom_value_with_meta(custom_value)
            else
              custom_field.cast_value custom_value.try(:value)
            end
          end
        else
          work_packages.map do |work_package|
            # Note: Doing as_json here because if we just take the value.attributes then we can't get any methods later.
            #       Name and subject are the default properties that the front end currently looks for to summarize an object.
            raise 'API Error: Unknown column name' if !work_package.respond_to?(column_name)
            value = work_package.send(column_name)
            value.is_a?(ActiveRecord::Base) ? value.as_json(only: 'id', methods: [:name, :subject]) : value
          end
        end
      end

      def column_should_be_summed_up?(column_name)
        # see ::Query::Sums mix in
        column_is_numeric?(column_name) && Setting.work_package_list_summable_columns.include?(column_name.to_s)
      end

      def column_is_numeric?(column_name)
        # TODO RS: We want to leave out ids even though they are numeric
        [:integer, :float].include? column_type(column_name)
      end

      def column_type(column_name)
        if column_name =~ /cf_(.*)/
          CustomField.find($1).field_format.to_sym
        else
          column = WorkPackage.columns_hash[column_name]
          column.nil? ? :none : column.type
        end
      end
    end
  end
end
