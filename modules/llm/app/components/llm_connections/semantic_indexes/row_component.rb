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
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :semantic_index, :model

      delegate :model_id, :context_token_length, :embedding_vector_dimensions, to: :semantic_index

      STATE_LABEL_SCHEMES = {
        "not_indexed" => :secondary,
        "indexing" => :attention,
        "ready" => :success,
        "failed" => :danger
      }.freeze

      def row_data
        { test_selector: "llm-semantic-index--row-#{semantic_index.id}" }
      end

      def title
        safe_join(
          [
            render(Primer::Beta::Text.new(font_weight: :bold, mr: 2)) { semantic_index.title },
            active_label,
            description
          ].compact
        )
      end

      def column_css_class(column)
        return "#{super} -no-ellipsis" if column == :status

        super
      end

      def status
        safe_join(
          [
            render(Primer::Beta::Label.new(scheme: STATE_LABEL_SCHEMES.fetch(semantic_index.state))) do
              I18n.t("admin.semantic_indexes.states.#{semantic_index.state}")
            end,
            indexing_progress,
            error_message
          ].compact
        )
      end

      def button_links
        [activate_button, start_indexing_button, action_menu].compact
      end

      private

      def active_label
        return unless semantic_index.active?

        render(Primer::Beta::Label.new(scheme: :accent, test_selector: "llm-semantic-index--active-label")) do
          I18n.t("admin.semantic_indexes.active")
        end
      end

      def activate_button
        return unless semantic_index.ready? && !semantic_index.active?

        render(
          Primer::Beta::Button.new(
            size: :small,
            tag: :a,
            href: activation_dialog_semantic_index_path(semantic_index),
            data: { controller: "async-dialog" },
            test_selector: "llm-semantic-index--activate-#{semantic_index.id}"
          )
        ) { I18n.t("admin.semantic_indexes.activate.button") }
      end

      def description
        return if semantic_index.description.blank?

        render(Primer::Beta::Text.new(tag: :div, color: :muted, font_size: :small, classes: "ellipsis")) do
          semantic_index.description
        end
      end

      def indexing_progress
        return unless semantic_index.indexing?

        render(Primer::Box.new(mt: 1, test_selector: "llm-semantic-index--progress-#{semantic_index.id}")) do
          safe_join(
            [
              render(Primer::Beta::ProgressBar.new(size: :small)) do |bar|
                bar.with_item(percentage: indexing_percentage, bg: :success_emphasis)
              end,
              render(Primer::Beta::Text.new(tag: :div, color: :subtle, font_size: :small, mt: 1)) do
                I18n.t("admin.semantic_indexes.indexing.progress", percentage: indexing_percentage)
              end
            ]
          )
        end
      end

      def indexing_percentage
        @indexing_percentage ||= begin
          batch = semantic_index.indexing_batch
          batch ? Llm::IndexingProgress.new(batch).percentage : 0
        end
      end

      def start_indexing_button
        return unless semantic_index.indexable?

        helpers.form_with(url: start_indexing_semantic_index_path(semantic_index),
                          method: :post,
                          class: "d-inline-block") do
          render(
            Primer::Beta::Button.new(
              type: :submit,
              size: :small,
              test_selector: "llm-semantic-index--start-indexing-#{semantic_index.id}"
            )
          ) do |button|
            button.with_leading_visual_icon(icon: semantic_index.not_indexed? ? :play : :sync)
            I18n.t(semantic_index.state, scope: "admin.semantic_indexes.start_indexing.button")
          end
        end
      end

      def error_message
        return unless semantic_index.failed? && semantic_index.error_message.present?

        render(Primer::Beta::Text.new(tag: :div, color: :danger, font_size: :small, mt: 1)) do
          semantic_index.error_message
        end
      end

      def action_menu
        render(Primer::Alpha::ActionMenu.new(anchor_align: :end,
                                             test_selector: "llm-semantic-index--menu-#{semantic_index.id}")) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": I18n.t(:label_more), scheme: :invisible, size: :small)

          edit_item(menu)
          menu.with_divider
          semantic_index.active? ? locked_delete_item(menu) : delete_item(menu)
        end
      end

      def edit_item(menu)
        menu.with_item(
          label: I18n.t(:button_edit),
          tag: :a,
          href: edit_dialog_semantic_index_path(semantic_index),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def locked_delete_item(menu)
        menu.with_item(label: I18n.t("admin.semantic_indexes.menu.delete"), disabled: true) do |item|
          item.with_leading_visual_icon(icon: :trash)
          item.with_description { I18n.t("admin.semantic_indexes.menu.locked_while_active") }
        end
      end

      def delete_item(menu)
        menu.with_item(
          label: I18n.t("admin.semantic_indexes.menu.delete"),
          tag: :a,
          href: deletion_dialog_semantic_index_path(semantic_index),
          scheme: semantic_index.indexing? ? :default : :danger,
          disabled: semantic_index.indexing?,
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end
    end
  end
end
