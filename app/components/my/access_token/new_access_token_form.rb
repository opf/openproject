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

module My
  module AccessToken
    class NewAccessTokenForm < ApplicationForm
      EXPIRY_PRESETS = [7.days, 30.days, 60.days, 90.days].freeze
      CUSTOM_EXPIRY = "custom"
      NO_EXPIRY = "never"
      EXPIRY_TARGET_NAME = "token-expiry"

      form do |new_access_token_form|
        new_access_token_form.text_field(
          name: :token_name,
          autofocus: true,
          autocomplete: "off",
          label: I18n.t(:name_label, scope: i18n_scope),
          caption: I18n.t(:name_caption, scope: i18n_scope, default: ""),
          visually_hide_label: false,
          required: true
        )

        if model.is_a?(Token::Expirable)
          new_access_token_form.select_list(
            name: :expiry,
            label: I18n.t(:expiry_label, scope: i18n_scope),
            data: { target_name: EXPIRY_TARGET_NAME, "show-when-value-selected-target": "cause" }
          ) do |list|
            EXPIRY_PRESETS.each do |duration|
              date = today + duration
              list.option(
                value: date.iso8601,
                label: I18n.t(:expiry_preset, scope: i18n_scope, count: duration.in_days.to_i, date: helpers.format_date(date)),
                selected: selected_expiry == date.iso8601
              )
            end
            list.option(value: CUSTOM_EXPIRY,
                        label: I18n.t(:expiry_custom, scope: i18n_scope),
                        selected: selected_expiry == CUSTOM_EXPIRY)
            list.option(value: NO_EXPIRY,
                        label: I18n.t(:expiry_never, scope: i18n_scope),
                        selected: selected_expiry == NO_EXPIRY)
          end

          new_access_token_form.group(
            hidden: selected_expiry != CUSTOM_EXPIRY,
            data: { show_when_value_selected_target: "effect", target_name: EXPIRY_TARGET_NAME, value: CUSTOM_EXPIRY }
          ) do |custom_expiry|
            custom_expiry.single_date_picker(
              name: :expires_on_date,
              label: attribute_name(:expires_on),
              caption: I18n.t(:expires_on_caption, scope: i18n_scope),
              value: model.expires_on_date&.iso8601,
              input_width: :small,
              leading_visual: { icon: :calendar },
              datepicker_options: { inDialog: NewAccessTokenDialogComponent::DIALOG_ID },
              validation_message: model.errors.full_messages_for(:expires_on).to_sentence.presence
            )
          end
        end
      end

      private

      def selected_expiry
        return CUSTOM_EXPIRY if model.errors.include?(:expires_on)
        return NO_EXPIRY if model.expires_on.nil?

        selected_date = model.expires_on_date.iso8601
        preset_dates = EXPIRY_PRESETS.map { |duration| (today + duration).iso8601 }
        preset_dates.include?(selected_date) ? selected_date : CUSTOM_EXPIRY
      end

      def today
        model.user.time_zone.today
      end

      def i18n_scope
        [:my, :access_token, :dialog, model.model_name.i18n_key]
      end
    end
  end
end
