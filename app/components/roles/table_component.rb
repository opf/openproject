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

module Roles
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :global
    main_column :name
    mobile_columns :name
    mobile_labels :global

    def mobile_title
      Role.model_name.human(count: 2)
    end

    def row_class
      RowComponent
    end

    def has_actions?
      true
    end

    def headers
      [
        [:name, { caption: Role.model_name.human }],
        [:global, { caption: t(:label_global) }]
      ]
    end

    def container_id
      "roles-table"
    end

    def container_data
      {
        controller: "sortable-lists sortable-lists--list",
        sortable_lists_move_url_template_value: move_url_template,
        sortable_lists_sortable_lists__list_outlet: "##{container_id}",
        sortable_lists_sortable_lists__item_outlet: "##{container_id} [data-controller~='sortable-lists--item']",
        sortable_lists__list_type_value: Role::SORTABLE_LIST_TYPE,
        sortable_lists__list_accepted_type_value: Role::SORTABLE_LIST_TYPE,
        sortable_lists__list_name_value: Role.model_name.human(count: 2),
        # The list controller looks for its rows under `:scope > ul` by default, which the
        # border box table does not render.
        "sortable-lists--list-rows-container-element": ":scope > .#{rows_container_class}"
      }
    end

    private

    # Built from the route helper with a sentinel so relative-URL-root
    # installations keep working; {id} is expanded client-side.
    def move_url_template
      id_placeholder = "__id__"
      drop_role_path(id_placeholder).sub(id_placeholder, "{id}")
    end
  end
end
