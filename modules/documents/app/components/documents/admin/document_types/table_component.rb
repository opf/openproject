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

module Documents
  module Admin
    module DocumentTypes
      class TableComponent < OpPrimer::BorderBoxTableComponent
        columns :name, :documents_count
        main_column :name
        mobile_columns :name

        def row_class = ::Documents::Admin::DocumentTypes::RowComponent

        def has_actions? = true

        def mobile_title = DocumentType.model_name.human(count: :other)

        def container_id = "document-types-table"

        def headers
          [
            [:name, { caption: I18n.t("documents.index_page.type") }],
            [:documents_count, { caption: I18n.t(:label_documents) }]
          ]
        end

        def blank_title = I18n.t(:no_results_title_text)

        def blank_description = nil

        def container_data
          {
            controller: "sortable-lists--list",
            sortable_lists__list_type_value: DocumentType.model_name.param_key,
            sortable_lists__list_accepted_type_value: DocumentType.model_name.param_key,
            sortable_lists__list_name_value: DocumentType.model_name.human(count: :other),
            # The rows sit in a div, not in the `ul` the list controller looks for by default.
            sortable_lists__list_rows_container_element: ":scope > .#{rows_container_class}"
          }
        end
      end
    end
  end
end
