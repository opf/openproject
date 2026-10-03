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

module WorkPackageTypes
  module FormConfiguration
    class GroupComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include SortableLists::MoveMenu

      def initialize(group:, context:, ee_available: false, first: false, last: false, edit_mode: false,
                     form_model: nil)
        super(group)
        @group = group
        @context = context
        @ee_available = ee_available
        @first = first
        @last = last
        @edit_mode = edit_mode
        @form_model = form_model
        @instance_uid = SecureRandom.hex(4)
      end

      def wrapper_uniq_by
        @group[:id].presence || @group[:key].presence || @instance_uid
      end

      def edit_mode?
        @edit_mode
      end

      delegate :readonly?, :exclusions, to: :@context

      def query_group?
        @group[:type].to_s == "query"
      end

      def attributes
        @group[:attributes] || []
      end

      def first?
        @first
      end

      def last?
        @last
      end

      def ee_available?
        @ee_available
      end

      private

      def wrapper_data
        {
          group_type: @group[:type].to_s,
          group_key: @group[:key].to_s,
          group_query: @group[:query],
          update_query_url: update_query_path,
          edit_mode: (true if edit_mode?)
        }.compact.merge(item_data)
      end

      def group_name
        @group[:name]
      end

      def temporary_group?
        @group[:temporary]
      end

      def sole_group? = first? && last?

      def sortable?
        !readonly? && @group[:id].present? && !temporary_group?
      end

      def droppable_list?
        sortable? && !query_group?
      end

      def list_container
        uid = @group[:id].presence || key_digest || @instance_uid
        "form-configuration-group-#{uid}"
      end

      def key_digest
        Digest::SHA256.hexdigest(@group[:key].to_s)[0, 12] if @group[:key].present?
      end

      def empty_state_behavior
        droppable_list? ? :dynamic : :none
      end

      def header_arguments
        {
          title: group_name.presence || t("types.edit.form_configuration.new_group_title"),
          title_tag: :h3,
          state: edit_mode? ? :edit : :show,
          show_drag_handle: !readonly?,
          drag_handle_arguments: {
            classes: "group-handle",
            "aria-label": t("types.edit.form_configuration.drag_to_reorder"),
            test_selector: "type-form-configuration-group-handle-#{@group[:key]}",
            data: { sortable_lists__item_target: "handle" }
          }
        }
      end

      def group_menu_arguments
        {
          button_arguments: {
            size: :small,
            test_selector: "type-form-configuration-group-actions-#{@group[:key]}",
            aria: { label: t("types.edit.form_configuration.group_actions") }
          }
        }
      end

      def group_menu_items(menu)
        with_item_group(menu) { rename_item(menu) } if ee_available?
        with_item_group(menu) { with_move_items(menu) } unless sole_group?
        with_item_group(menu) { delete_item(menu) } if ee_available?
      end

      def rename_item(menu)
        menu.with_item(
          label: t("types.edit.form_configuration.rename_group"),
          test_selector: "type-form-configuration-group-rename-#{@group[:key]}",
          tag: :a,
          href: edit_path,
          content_arguments: { data: { turbo_stream: true } }
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def delete_item(menu)
        menu.with_item(
          label: t("button_delete"),
          scheme: :danger,
          tag: :a,
          href: destroy_path,
          content_arguments: {
            data: {
              turbo_method: :delete,
              turbo_stream: true,
              turbo_confirm: t("types.edit.form_configuration.confirm_delete_group")
            }
          }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def title_form_arguments
        {
          model: form_model,
          scope: :group,
          input_name: :name,
          url: update_path,
          method: form_method,
          label: t("types.edit.form_configuration.group_name_label"),
          hidden_fields: { group_type: form_model.group_type, query: form_model.query.presence },
          input_arguments: { validation_message: name_validation_message }.compact,
          cancel_arguments: { href: cancel_edit_path, data: { turbo_method: :post, turbo_stream: true } },
          data: { turbo_stream: true }
        }
      end

      def name_validation_message
        form_model.errors.messages_for(:name).to_sentence.presence
      end

      def form_model
        @form_model ||= GroupFormModel.from_group(@group)
      end

      def query_menu_arguments
        {
          menu_id: "#{list_container}-query-menu",
          button_arguments: {
            size: :small,
            test_selector: "type-form-configuration-query-actions-#{@group[:key]}",
            aria: { label: t("types.edit.form_configuration.row_actions") }
          }
        }
      end

      def query_menu_items(menu)
        menu.with_item(
          label: t("types.edit.form_configuration.edit_query"),
          test_selector: "type-form-configuration-edit-query-#{@group[:key]}",
          tag: :button,
          content_arguments: { data: { action: "click->admin--type-form-configuration--main#editQuery" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def attribute_row(attribute)
        GroupAttributeRowComponent.new(attribute:, context: @context, total_count: attributes.length)
      end

      def item_data
        return {} unless sortable?

        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: @group[:id],
          sortable_lists__item_type_value: SortableTypes::GROUP,
          sortable_lists__item_label_value: group_name,
          sortable_lists__item_mobility_value: ("fixed" if edit_mode?)
        }.compact
      end

      def box_data
        return {} unless sortable?

        preview = { sortable_lists__item_target: "preview" }
        return preview if query_group?

        preview.merge(
          controller: "sortable-lists--list",
          sortable_lists__list_type_value: SortableTypes::ATTRIBUTE,
          sortable_lists__list_accepted_type_value: SortableTypes::ATTRIBUTE,
          sortable_lists__list_id_value: @group[:id],
          sortable_lists__list_name_value: group_name
        )
      end

      def attribute_item_data(attribute)
        return {} if readonly?

        data = { attr_key: attribute[:key], attr_translation: attribute[:translation], attr_is_cf: attribute[:is_cf] }
        return data if attribute[:id].blank?

        data.merge(
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: attribute[:id],
          sortable_lists__item_type_value: SortableTypes::ATTRIBUTE,
          sortable_lists__item_label_value: attribute[:translation]
        )
      end

      def update_query_path
        @context.group_path(:update_query, key: @group[:key])
      end

      def edit_path
        @context.group_path(:edit, key: @group[:key])
      end

      def update_path
        temporary_group? ? @context.group_path : @context.group_path(key: @group[:key])
      end

      def form_method
        temporary_group? ? :post : :patch
      end

      def cancel_edit_path
        @context.group_path(:cancel_edit, key: @group[:key])
      end

      def destroy_path
        @context.group_path(key: @group[:key])
      end
    end
  end
end
