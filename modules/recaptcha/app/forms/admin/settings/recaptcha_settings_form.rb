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

module Admin
  module Settings
    class RecaptchaSettingsForm < ApplicationForm
      include ::RecaptchaHelper

      form do |f|
        f.select_list(name: :recaptcha_type,
                      label: I18n.t("recaptcha.settings.type"),
                      caption: helpers.t(
                        "recaptcha.settings.captcha_description_html",
                        hcaptcha_link: helpers.link_to("https://docs.hcaptcha.com/switch/", "https://docs.hcaptcha.com/switch/",
                                                       target: "_blank", rel: "noopener"),
                        recaptcha_link: helpers.link_to("https://www.google.com/recaptcha", "https://www.google.com/recaptcha",
                                                        target: "_blank", rel: "noopener"),
                        turnstile_link: helpers.link_to("https://developers.cloudflare.com/turnstile/",
                                                        "https://developers.cloudflare.com/turnstile/",
                                                        target: "_blank", rel: "noopener")
                      ),
                      input_width: :medium) do |list|
          recaptcha_available_options.each do |label, value|
            list.option(label:,
                        value:,
                        selected: value == Setting.plugin_openproject_recaptcha["recaptcha_type"])
          end
        end

        f.text_field(
          name: :website_key,
          label: I18n.t("recaptcha.settings.website_key"),
          caption: I18n.t("recaptcha.settings.website_key_text"),
          value: Setting.plugin_openproject_recaptcha["website_key"],
          input_width: :large
        )

        f.text_field(
          name: :secret_key,
          label: I18n.t("recaptcha.settings.secret_key"),
          caption: I18n.t("recaptcha.settings.secret_key_text"),
          value: Setting.plugin_openproject_recaptcha["secret_key"],
          input_width: :large
        )

        f.text_field(
          name: :response_limit,
          type: :number,
          label: I18n.t("recaptcha.settings.response_limit"),
          caption: I18n.t("recaptcha.settings.response_limit_text"),
          value: Setting.plugin_openproject_recaptcha["response_limit"],
          input_width: :xsmall
        )

        f.submit(name: :submit,
                 label: I18n.t(:button_save),
                 scheme: :primary)
      end
    end
  end
end
