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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  module SemanticIndexes
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :title, :model_id, :context_token_length, :embedding_vector_dimensions, :status

      main_column :title

      mobile_columns :title, :status

      mobile_labels :status

      def has_actions? = true

      def has_footer? = false

      def blank_title = I18n.t("admin.semantic_indexes.box.empty_title")

      def blank_description = I18n.t("admin.semantic_indexes.box.empty_description")

      def blank_icon = :search

      def mobile_title = I18n.t("admin.semantic_indexes.box.title")

      def headers
        [
          [:title, { caption: SemanticIndex.human_attribute_name(:title) }],
          [:model_id, { caption: SemanticIndex.human_attribute_name(:model_id) }],
          [:context_token_length, { caption: SemanticIndex.human_attribute_name(:context_token_length) }],
          [:embedding_vector_dimensions, { caption: SemanticIndex.human_attribute_name(:embedding_vector_dimensions) }],
          [:status, { caption: SemanticIndex.human_attribute_name(:state) }]
        ]
      end
    end
  end
end
