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
    class GroupForm < ApplicationForm
      form do |group_form|
        group_form.hidden(name: :group_type, value: model.group_type)
        group_form.hidden(name: :query, value: model.query) if model.query.present?

        group_form.group(layout: :horizontal) do |row|
          row.text_field(
            name: :name,
            label: I18n.t("types.edit.form_configuration.group_name_label"),
            visually_hide_label: true,
            value: model.name,
            required: true,
            autofocus: true,
            autocomplete: "off",
            validation_message: validation_message_for(:name),
            data: { "test-selector": "type-form-configuration-group-name-input" }
          )
          row.button(
            name: :cancel,
            tag: :a,
            label: I18n.t("button_cancel"),
            scheme: :secondary,
            href: @cancel_path,
            data: {
              turbo_method: :post,
              turbo_stream: true
            },
            test_selector: "type-form-configuration-group-cancel"
          )
          row.submit(
            name: :submit,
            label: I18n.t("button_save"),
            scheme: :primary,
            test_selector: "type-form-configuration-group-save"
          )
        end
      end

      def initialize(cancel_path:)
        super()
        @cancel_path = cancel_path
      end

      private

      def validation_message_for(attribute)
        model.errors.messages_for(attribute).to_sentence.presence
      end
    end
  end
end
