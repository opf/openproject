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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  # Lists the models the remote server reported, read from the cached catalogue.
  #
  # Rendering never issues an HTTP request: the catalogue is refreshed explicitly
  # through the "Refresh models" action.
  class ModelsTableComponent < OpPrimer::BorderBoxTableComponent
    columns :identifier, :context_window

    mobile_columns :identifier

    def initial_sort = %i[identifier asc]

    def has_footer? = false

    def mobile_title = I18n.t("admin.llm_connections.show.models_heading")

    # The row class is otherwise derived by convention as LlmConnections::RowComponent.
    def row_class = ModelsRowComponent

    def headers
      [
        [:identifier, { caption: I18n.t("admin.llm_connections.models.identifier") }],
        [:context_window, { caption: I18n.t("admin.llm_connections.models.context_window") }]
      ]
    end

    def blank_title = I18n.t("admin.llm_connections.models.blank_title")

    def blank_description = I18n.t("admin.llm_connections.models.blank_description")

    def blank_icon = :sparkle
  end
end
