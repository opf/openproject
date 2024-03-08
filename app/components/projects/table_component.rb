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
  # is an OP query.
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

    def initialize_sorted_model
      helpers.sort_clear

      orders = query.orders.select(&:valid?).map { |o| [o.attribute.to_s, o.direction.to_s] }
      helpers.sort_init orders
      helpers.sort_update orders.map(&:first)
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

    def deactivate_class_on_lft_sort
      if sorted_by_lft?
        "spot-link_inactive"
      end
    end

    def href_only_when_not_sort_lft
      unless sorted_by_lft?
        projects_path(
          sortBy: JSON.dump([%w[lft asc]]),
          **helpers.projects_query_params.slice(*helpers.projects_query_param_names_for_sort)
        )
      end
    end

    def order_options(select)
      {
        caption: select.caption
      }
    end

    def sortable_column?(select)
      sortable? && query.known_order?(select.attribute)
    end

    def columns
      @columns ||= begin
        columns = query.selects.reject { |select| select.is_a?(::Queries::Selects::NotExistingSelect) }

        index = columns.index { |column| column.attribute == :name }
        columns.insert(index, ::Queries::Projects::Selects::Default.new(:hierarchy)) if index

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

    def sorted_by_lft?
      query.orders.first&.attribute == :lft
    end

    # TODO: copied from ::TableComponent
    def render_collection(rows)
      render(self.class.row_class.with_collection(rows, table: self))
    end

    def inline_create_link
      nil
    end

    class << self
      def row_class
        mod = name.split("::")[0..-2].join("::").presence || "Table"

        "#{mod}::RowComponent".constantize
      rescue NameError
        raise(
          NameError,
          "#{mod}::RowComponent required by #{mod}::TableComponent not defined. " +
            "Expected to be defined in `app/components/#{mod.underscore}/row_component.rb`."
        )
      end
    end

    # END copied from ::TableComponent

    # TODO: copied from sort_helper.rb

    def sort_link(column, options)
      order = order_string(column, inverted: true) || 'asc'

      orders = [[column.attribute, order]] + ordered_by
                                               .reject { |o| [column.attribute, :lft].include?(o.attribute) }
                                               .map { |o| [o.attribute, o.direction] }

      link_to(column.caption, { sortBy: JSON::dump(orders[0..2]) }, options)
    end

    # Returns a table header <th> tag with a sort link for the named column
    # attribute.
    def sort_header_tag(column, options)
      options[:title] = sort_header_title(column)

      helpers.within_sort_header_tag_hierarchy(options, sort_class(column)) do
        sort_link(column, options)
      end
    end

    def sort_class(column)
      order = order_string(column)

      order.nil? ? nil : "sort #{order}"
    end

    def order_string(column, inverted: false)
      if column.attribute == first_order_by.attribute
        if first_order_by.asc?
          inverted ? 'desc' : 'asc'
        else
          inverted ? 'asc' : 'desc'
        end
      end
    end

    def sort_header_title(column)
      if column.attribute == first_order_by.attribute
        order = first_order_by.asc? ? t(:label_ascending) : t(:label_descending)
        order + " #{t(:label_sorted_by, value: "\"#{column.caption}\"")}"
      else
        t(:label_sort_by, value: "\"#{column.caption}\"")
      end
    end

    # END copied from sort_helper.rb

    def first_order_by
      ordered_by.first
    end

    def ordered_by
      @ordered_by ||= query.orders.select(&:valid?)
    end
  end
end
