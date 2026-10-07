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

module Admin
  module Settings
    class UsersSettings::UserConsentForm < ApplicationForm
      settings_form do |sf|
        sf.fieldset_group(title: I18n.t(:label_consent_settings)) do |fg|
          fg.check_box(name: :consent_required)
          fg.multi_language_text_select(
            name: :consent_info,
            current_language: I18n.locale.to_s
          )
          fg.object.check_box(
            name: :toggle_consent_time,
            label: I18n.t(:setting_consent_time),
            value: "1",
            checked: Setting.consent_time.blank?,
            scope_name_to_model: false,
            scope_id_to_model: false,
            caption: consent_time_caption
          )
          fg.text_field(
            name: :consent_decline_mail,
            type: :email,
            input_width: :medium,
            caption: I18n.t(:"consent.contact_mail_instructions")
          )
        end
      end

      private

      def consent_time_caption
        update_time = Setting.consent_time.present? ? helpers.format_time(Setting.consent_time) : I18n.t(:label_never)

        helpers.safe_join(
          [
            I18n.t("consent.text_update_consent_time"),
            helpers.tag.br,
            helpers.tag.strong(I18n.t("consent.update_consent_last_time", update_time:))
          ]
        )
      end
    end
  end
end
