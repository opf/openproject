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

module CustomFields
  module Hierarchy
    class NewItemForm < ApplicationForm
      form do |new_item_form|
        new_item_form.group(layout: :horizontal) do |input_group|
          input_group.text_field(
            name: :label,
            label: "Label",
            value: @label,
            visually_hide_label: true,
            required: true,
            placeholder: I18n.t("custom_fields.admin.items.placeholder.label"),
            validation_message: validation_message_for(:label)
          )
          input_group.text_field(
            name: :short,
            label: "Short",
            value: @short,
            visually_hide_label: true,
            full_width: false,
            required: false,
            placeholder: I18n.t("custom_fields.admin.items.placeholder.short")
          )
        end

        new_item_form.group(layout: :horizontal) do |button_group|
          button_group.button(name: :cancel,
                              tag: :a,
                              label: I18n.t(:button_cancel),
                              scheme: :default,
                              data: { turbo_stream: true },
                              href: url_helpers.custom_field_items_path(@custom_field))
          button_group.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
        end
      end

      def initialize(custom_field:, label:, short:)
        super()
        @custom_field = custom_field
        @label = label
        @short = short
      end

      private

      def validation_message_for(attribute)
        @custom_field
          .errors
          .messages_for(attribute)
          .to_sentence
          .presence
      end
    end
  end
end
