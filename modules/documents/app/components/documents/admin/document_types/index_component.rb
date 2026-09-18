# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Documents
  module Admin
    module DocumentTypes
      class IndexComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        options :enumerations

        alias_method :document_types, :enumerations

        private

        def wrapper_data_attributes
          {
            controller: "sortable-lists",
            sortable_lists_move_url_template_value: move_url_template,
            sortable_lists_sortable_lists__list_outlet: "##{wrapper_key} [data-controller~='sortable-lists--list']",
            sortable_lists_sortable_lists__item_outlet: "##{wrapper_key} [data-controller~='sortable-lists--item']"
          }
        end

        # Built from the route helper with a sentinel so relative-URL-root
        # installations keep working; {id} is expanded client-side.
        def move_url_template
          id_placeholder = "__id__"
          move_admin_settings_document_type_path(id_placeholder).sub(id_placeholder, "{id}")
        end
      end
    end
  end
end
