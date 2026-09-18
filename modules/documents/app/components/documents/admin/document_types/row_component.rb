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
      class RowComponent < OpPrimer::BorderBoxRowComponent
        include SortableLists::MoveMenu

        alias_method :document_type, :model

        def row_css_id = "document-type-#{document_type.id}"

        def row_data
          {
            test_selector: "document-type-row-#{document_type.id}",
            controller: "sortable-lists--item",
            # The row is its own preview target, so the drag image is the whole row.
            sortable_lists__item_target: "preview",
            sortable_lists__item_id_value: document_type.id,
            sortable_lists__item_type_value: DocumentType::SORTABLE_LIST_TYPE,
            sortable_lists__item_label_value: document_type.name
          }
        end

        def name
          flex_layout(align_items: :center) do |flex|
            flex.with_column(mr: 2) { drag_handle }
            flex.with_column(classes: "ellipsis") { name_link }
            flex.with_column(ml: 2) { inactive_label } unless document_type.active?
            flex.with_column(ml: 2) { default_label } if document_type.is_default?
          end
        end

        def documents_count
          render(Primer::Beta::Text.new(color: :subtle, test_selector: "documents-count")) do
            document_type.documents_count.to_s
          end
        end

        def button_links = [action_menu]

        private

        def drag_handle
          render(
            Primer::OpenProject::DragHandle.new(
              data: { sortable_lists__item_target: "handle" },
              classes: "hide-when-print"
            )
          )
        end

        def name_link
          render(
            Primer::Beta::Link.new(
              href: edit_admin_settings_document_type_path(document_type),
              underline: false
            )
          ) do
            render(Primer::Beta::Text.new(font_weight: :bold)) { document_type.name }
          end
        end

        def inactive_label
          render(Primer::Beta::Label.new(scheme: :default, test_selector: "label-inactive")) do
            I18n.t(:label_inactive)
          end
        end

        def default_label
          render(Primer::Beta::Label.new(scheme: :primary, test_selector: "label-is-default")) do
            I18n.t(:label_default)
          end
        end

        def action_menu
          render(
            Primer::Alpha::ActionMenu.new(
              test_selector: "op-document-types--action-menu",
              classes: "hide-when-print"
            )
          ) do |menu|
            menu.with_show_button(
              icon: "kebab-horizontal",
              scheme: :invisible,
              "aria-label": I18n.t("documents.document_type_actions")
            )

            build_document_type_menu(menu)
          end
        end

        def build_document_type_menu(menu)
          with_item_group(menu) do
            edit_document_type(menu)
            move_document_type(menu)
          end
          with_item_group(menu) { delete_document_type(menu) }
        end

        def edit_document_type(menu)
          menu.with_item(
            label: I18n.t(:button_edit),
            tag: :a,
            href: edit_admin_settings_document_type_path(document_type)
          ) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end

        def move_document_type(menu)
          menu.with_item(
            component_klass: Primer::Alpha::ActionMenu::SubMenuItem,
            label: I18n.t(:button_move),
            select_variant: :none,
            form_arguments: {},
            data: { sortable_lists__item_target: "moveMenu" }
          ) do |submenu|
            submenu.with_leading_visual_icon(icon: :"op-arrow-in")

            with_move_items(submenu)
          end
        end

        def delete_document_type(menu)
          menu.with_item(
            label: I18n.t(:button_delete),
            scheme: :danger,
            tag: :a,
            content_arguments: { data: { controller: "async-dialog" } },
            href: delete_dialog_admin_settings_document_type_path(document_type)
          ) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
