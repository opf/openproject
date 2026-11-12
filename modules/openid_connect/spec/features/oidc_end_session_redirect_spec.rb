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

require "spec_helper"

RSpec.describe "OpenID Connect end_session_redirect",
               :js,
               with_ee: %i[sso_auth_providers] do
  let!(:provider) do
    create(:oidc_provider,
           slug: "keycloak",
           end_session_endpoint: "https://example.com")
  end
  let(:user_menu) { Components::UserMenu.new }

  let(:password) { "password!123" }
  let(:user) { create(:user, authentication_provider: provider, password:, password_confirmation: password) }

  it "redirects to the OIDC logout endpoint without turbo (Regression #65076)" do
    login_with(user.login, password)

    visit home_path

    user_menu.open
    click_link_or_button "Sign out"

    expect(page).to have_current_path("https://example.com")
  end
end
