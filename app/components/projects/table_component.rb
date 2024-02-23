# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    options :query

    def initialize(**options)
      super(rows: [], **options)
    end

    def before_render
      @model = projects(query)
      super
    end

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
        instance_exec(model, &projects_enumerator)
      end
    end

    def initialize_sorted_model
      helpers.sort_clear

      orders = query.orders.select(&:valid?).map { |o| [o.attribute.to_s, o.direction.to_s] }
      helpers.sort_init orders
      helpers.sort_update orders.map(&:first)
    end

    def paginated?
      true
    end

    def deactivate_class_on_lft_sort
      if sorted_by_lft?
        'spot-link_inactive'
      end
    end

    def href_only_when_not_sort_lft
      unless sorted_by_lft?
        projects_path(sortBy: JSON::dump([['lft', 'asc']]))
      end
    end

    def order_options(select)
      {
        caption: select.caption,
        data:
          {
            controller: "params-from-query",
            'application-target': "dynamic",
            'params-from-query-allowed-value': '["query_id"]',
            'params-from-query-all-anchors-value': "true"
          }
      }
    end

    def sortable_column?(select)
      query.known_order?(select.attribute)
    end

    def columns
      @columns ||= begin
        columns = query.selects.reject { |select| select.is_a?(Queries::Selects::NotExistingSelect) }

        index = columns.index { |column| column.attribute == :name }
        columns.insert(index, Queries::Projects::Selects::Default.new(:hierarchy)) if index

        columns
      end
    end

    def projects(query)
      query
        .results
        .with_required_storage
        .with_latest_activity
        .includes(:custom_values, :enabled_modules)
        .paginate(page: helpers.page_param(params), per_page: helpers.per_page_param(params))
    end

    def projects_with_levels_order_sensitive(projects, &)
      if sorted_by_lft?
        Project.project_tree(projects, &)
      else
        projects_with_level(projects, &)
      end
    end

    def projects_with_level(projects, &)
      ancestors = []

      projects.each do |project|
        while !ancestors.empty? && !project.is_descendant_of?(ancestors.last)
          ancestors.pop
        end

        yield project, ancestors.count

        ancestors << project
      end
    end

    def sorted_by_lft?
      query.orders.first&.attribute == :lft
    end
  end
end
