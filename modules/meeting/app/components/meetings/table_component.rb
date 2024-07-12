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

module Meetings
  class TableComponent < ApplicationComponent
    options :params # We read collapsed state from params
    options :current_user # adds this option to those of the base class
    options :query

    def table_id
      "meeting-table"
    end

    def container_class
      "generic-table--container_visible-overflow generic-table--container_height-100"
    end

    def rows
      @rows ||= query.results.paginate(page: helpers.page_param(params), per_page: helpers.per_page_param(params))
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
      @columns ||= query.selects.reject { |select| select.is_a?(::Queries::Selects::NotExistingSelect) }
    end

    def render_rows
      render(self.class.row_class.with_collection(rows, table: self))
    end

    def render_column_headers
      # TODO: turn the Projects::ColumnHeaderComponent into generic component
      render(Projects::ColumnHeaderComponent.with_collection(columns, query:))
    end

    def inline_create_link
      nil
    end

    def empty_row_message
      I18n.t :no_results_title_text
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
  end
end
