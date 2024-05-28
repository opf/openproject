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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  # Not inheriting from TableComponent as that is AR scope based and here the model
  # is an OP query. The intend is to distill the common parts into an abstract TableComponent again once
  # another table is implemented with the same pattern.
  class TableComponent < ::ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    options :params # We read collapsed state from params
    options :current_user # adds this option to those of the base class
    options :query

    def before_render
      @model = projects(query)
      super
    end

    def table_id
      "project-table"
    end

    def container_class
      "generic-table--container_visible-overflow generic-table--container_height-100"
    end

    # We don't return the project row
    # but the [project, level] array from the helper
    def rows
      @rows ||= begin
        projects_enumerator = ->(model) { to_enum(:projects_with_levels_order_sensitive, model).to_a }
        instance_exec(model, &projects_enumerator)
      end
    end

    def paginated?
      true
    end

    def pagination_options
      default_pagination_options.merge(optional_pagination_options)
    end

    def default_pagination_options
      { allowed_params: %i[query_id filters columns sortBy] }
    end

    def optional_pagination_options
      {}
    end

    def sortable_column?(select)
      sortable? && query.known_order?(select.attribute)
    end

    def columns
      @columns ||= begin
        columns = query.selects.reject { |select| select.is_a?(::Queries::Selects::NotExistingSelect) }

        index = columns.index { |column| column.attribute == :name }
        columns.insert(index, ::Queries::Projects::Selects::Default.new(:lft)) if index

        columns
      end
    end

    def projects(query)
      query
        .results
        .includes(:enabled_modules)
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

    def favored_project_ids
      @favored_project_ids ||= Favorite.where(user: current_user, favored_type: "Project").pluck(:favored_id)
    end

    def render_rows
      render(self.class.row_class.with_collection(rows, table: self))
    end

    def render_column_headers
      render(Projects::ColumnHeaderComponent.with_collection(columns, query:))
    end

    def inline_create_link
      nil
    end

    class << self
      def row_class
        mod = name.deconstantize

        "#{mod}::RowComponent".constantize
      rescue NameError
        raise(
          NameError,
          "#{mod}::RowComponent required by #{mod}::TableComponent not defined. " +
            "Expected to be defined in `app/components/#{mod.underscore}/row_component.rb`."
        )
      end
    end

    def sorted_by_lft?
      query.orders.first&.attribute == :lft
    end
  end
end
