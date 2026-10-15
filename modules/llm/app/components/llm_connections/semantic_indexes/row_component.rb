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
  module SemanticIndexes
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :semantic_index, :model

      def row_data
        { test_selector: "llm-semantic-index--row-#{semantic_index.id}" }
      end

      def title
        safe_join(
          [
            render(Primer::Beta::Text.new(font_weight: :bold)) { semantic_index.title },
            description
          ].compact
        )
      end

      delegate :model_id, :context_token_length, :embedding_vector_dimensions, to: :semantic_index

      def status
        render(Primer::Beta::Label.new(scheme: :secondary)) do
          I18n.t("admin.semantic_indexes.states.#{semantic_index.state}")
        end
      end

      def button_links
        [action_menu]
      end

      private

      def description
        return if semantic_index.description.blank?

        render(Primer::Beta::Text.new(tag: :div, color: :subtle, font_size: :small, classes: "ellipsis")) do
          semantic_index.description
        end
      end

      def action_menu
        render(Primer::Alpha::ActionMenu.new(anchor_align: :end,
                                             test_selector: "llm-semantic-index--menu-#{semantic_index.id}")) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": I18n.t(:label_more), scheme: :invisible)

          menu.with_item(
            label: I18n.t(:button_edit),
            tag: :a,
            href: edit_dialog_semantic_index_path(semantic_index),
            content_arguments: { data: { controller: "async-dialog" } }
          ) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end

          menu.with_item(
            label: I18n.t("admin.semantic_indexes.menu.delete"),
            scheme: :danger,
            tag: :a,
            href: deletion_dialog_semantic_index_path(semantic_index),
            content_arguments: { data: { controller: "async-dialog" } }
          ) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
