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
    class RecaptchaSettingsForm < ApplicationForm
      delegate :link_to, :link_translate, to: :@view_context

      form do |f|
        f.advanced_radio_button_group(
          name: :recaptcha_type,
          label: I18n.t("recaptcha.settings.type")
        ) do |radio_group|
          available_caption_types.each do |label, value, options = {}|
            radio_group.radio_button(
              label:,
              value:,
              checked: value == Setting.plugin_openproject_recaptcha["recaptcha_type"],
              **options
            )
          end
        end

        f.text_field(
          name: :website_key,
          label: I18n.t("recaptcha.settings.website_key"),
          value: Setting.plugin_openproject_recaptcha["website_key"],
          input_width: :medium
        )

        f.text_field(
          name: :secret_key,
          label: I18n.t("recaptcha.settings.secret_key"),
          value: Setting.plugin_openproject_recaptcha["secret_key"],
          caption: I18n.t("recaptcha.settings.secret_key_text"),
          input_width: :medium
        )

        f.text_field(
          name: :response_limit,
          type: :number,
          label: I18n.t("recaptcha.settings.response_limit"),
          value: Setting.plugin_openproject_recaptcha["response_limit"],
          caption: I18n.t("recaptcha.settings.response_limit_text"),
          input_width: :xsmall
        )

        f.submit(
          scheme: :primary,
          name: :submit,
          label: I18n.t(:button_save)
        )
      end

      private

      def available_caption_types
        OpenProject::Recaptcha::Services::AVAILABLE.map { [I18n.t("recaptcha.settings.type_#{it.id}"), it.value, { trailing_image: it.icon }] }
      end

      def recaptcha_settings
        Setting.plugin_openproject_recaptcha
      end
    end
  end
end
