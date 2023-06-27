# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Projects
  class TableComponent < ::TableComponent
    options :params # We read collapsed state from params
    options :current_user # adds this option to those of the base class

    def initial_sort
      %i[lft asc]
    end

    def table_id
      'project-table'
    end

    ##
    # The project sort by is handled differently
    def build_sort_header(column, options)
      helpers.projects_sort_header_tag(column, options.merge(param: :json))
    end

    # We don't return the project row
    # but the [project, level] array from the helper
    def rows
      @rows ||= begin
        projects_enumerator = ->(model) { to_enum(:projects_with_levels_order_sensitive, model).to_a } # rubocop:disable Lint/ToEnumArguments
        helpers.instance_exec(model, &projects_enumerator)
      end
    end

    def initialize_sorted_model
      helpers.sort_clear

      orders = options[:orders]
      helpers.sort_init orders
      helpers.sort_update orders.map(&:first)
    end

    def paginated?
      true
    end

    def deactivate_class_on_lft_sort
      if helpers.sorted_by_lft?
        'spot-link_inactive'
      end
    end

    def href_only_when_not_sort_lft
      unless helpers.sorted_by_lft?
        projects_path(sortBy: JSON::dump([['lft', 'asc']]))
      end
    end

    def all_columns
      @all_columns ||= [
        [:hierarchy, { builtin: true }],
        [:name, { builtin: true, caption: Project.human_attribute_name(:name) }],
        [:project_status, { caption: Project.human_attribute_name(:status) }],
        [:status_explanation, { caption: Project.human_attribute_name(:status_explanation) }],
        [:public, { caption: Project.human_attribute_name(:public) }],
        *custom_field_columns,
        *admin_columns
      ]
    end

    def headers
      all_columns
        .select do |name, options|
        options[:builtin] || Setting.enabled_projects_columns.include?(name.to_s)
      end
    end

    def sortable_column?(_column)
      true
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def admin_columns
      return [] unless current_user.admin?

      [
        [:created_at, { caption: Project.human_attribute_name(:created_at) }],
        [:latest_activity_at, { caption: Project.human_attribute_name(:latest_activity_at) }],
        [:required_disk_space, { caption: I18n.t(:label_required_disk_storage) }]
      ]
    end

    def custom_field_columns
      project_custom_fields.values.map do |custom_field|
        [custom_field.column_name.to_sym, { caption: custom_field.name, custom_field: true }]
      end
    end

    def project_custom_fields
      @project_custom_fields ||= begin
        fields =
          if EnterpriseToken.allows_to?(:custom_fields_in_projects_list)
            ProjectCustomField.visible(current_user).order(:position)
          else
            ProjectCustomField.none
          end

        fields
          .index_by { |cf| cf.column_name.to_sym }
      end
    end
  end
end
