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

module Settings
  class AuthenticationSettingsForm < ApplicationForm
    class SessionTtlForm < ApplicationForm
      settings_form do |f|
        f.group(ml: -4) do |g|
          g.text_field(
            name: :session_ttl,
            type: :number,
            size: 6,
            min: 0,
            caption: I18n.t("setting_session_ttl_hint"),
            trailing_visual: { text: { id: "settings_session_ttl_unit", text: I18n.t(:label_minute_plural) } },
            input_width: :small,
            aria: { describedby: "settings_session_ttl_unit" }
          )
        end
      end
    end

    settings_form do |f|
      f.select_list(
        name: :autologin,
        input_width: :medium,
        label: I18n.t(:setting_autologin)
      ) do |select|
        select.option(
          value: 0,
          label: I18n.t(:label_disabled),
          selected: Setting.autologin == 0
        )

        Settings::Definition[:autologin].allowed.each do |days|
          select.option(
            value: days,
            label: I18n.t("datetime.distance_in_words.x_days", count: days),
            selected: Setting.autologin == days
          )
        end
      end

      f.check_box(
        name: :session_ttl_enabled,
        data: {
          target_name: "session-ttl-enabled",
          show_when_checked_target: "cause"
        }
      ) do |session_ttl_check_box|
        session_ttl_check_box.nested_form(
          classes: ["mt-2", { "d-none" => !Setting.session_ttl_enabled? }],
          data: {
            target_name: "session-ttl-enabled",
            show_when_checked_target: "effect",
            show_when: "checked"
          }
        ) do |builder|
          SessionTtlForm.new(builder)
        end
      end

      f.check_box(name: :log_requesting_user)

      f.text_field(
        name: :after_first_login_redirect_url,
        caption: helpers.t(:setting_after_first_login_redirect_url_text_html),
        input_width: :large
      )

      f.text_field(
        name: :after_login_default_redirect_url,
        caption: helpers.t(:setting_after_login_default_redirect_url_example_html,
                           example_code: helpers.content_tag(:code, "/my/page")),
        input_width: :large
      )

      f.submit
    end
  end
end
