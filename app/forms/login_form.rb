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

class LoginForm < ApplicationForm
  include ApplicationHelper
  include OpPrimer::ComponentHelpers

  form do |f|
    f.hidden(name: "back_url", value: @back_url) if @back_url.present?

    f.text_field(
      name: :username,
      id: "username#{@id_suffix}",
      value: @username,
      autofocus: @username.blank?,
      label: I18n.t("account.username_or_email"),
      required: true,
      autocomplete: "username"
    )

    f.text_field(
      name: :password,
      id: "password#{@id_suffix}",
      type: :password,
      autofocus: @username.present?,
      label: User.human_attribute_name(:password),
      required: true,
      autocomplete: "current-password"
    )

    autologin = Setting::Autologin.enabled?
    lost_password = Setting.lost_password?

    if autologin || lost_password
      f.group(layout: :horizontal,
              justify_content: autologin ? :space_between : :flex_end,
              align_items: :center) do |g|
        if autologin
          g.check_box name: "autologin",
                      id: "autologin#{@id_suffix}",
                      checked: false,
                      value: 1,
                      label: I18n.t("users.autologins.prompt",
                                    num_days: I18n.t("datetime.distance_in_words.x_days", count: Setting.autologin))
        end

        if lost_password
          g.html_content do
            render(Primer::Beta::Link.new(href: url_helpers.account_lost_password_path)) { I18n.t(:label_password_lost) }
          end
        end
      end
    end

    f.submit(name: "login", label: I18n.t(:button_login), scheme: :primary, block: true)
  end

  def initialize(back_url: nil, username: nil, id_suffix: nil)
    super()
    @back_url = back_url
    @username = username
    @id_suffix = id_suffix
  end
end
