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

module OmniauthSpecHelpers
  def start_omniauth_developer
    visit signin_path unless omniauth_developer_flow_visible?

    if page.has_css?(".auth-provider-developer", wait: 0)
      click_link_or_button "Omniauth Developer", match: :first
    end

    submit_omniauth_direct_login_form
  end

  def submit_omniauth_direct_login_form
    return unless page.has_css?("#omniauth-direct-login-form", wait: 0)

    click_button I18n.t("account.omniauth_direct_login_continue")
  end

  def omniauth_developer_flow_visible?
    page.has_css?(".auth-provider-developer, #omniauth-direct-login-form", wait: 0) ||
      page.has_field?("first_name", wait: 0)
  end
end

RSpec.configure do |config|
  config.include OmniauthSpecHelpers, type: :feature

  config.before :each, type: :feature do
    OmniAuth.config.mock_auth[:developer] = nil
  end
end
