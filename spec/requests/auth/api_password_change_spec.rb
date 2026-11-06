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

RSpec.describe "API password change session revocation",
               :skip_csrf,
               type: :rails_request,
               with_config: { drop_old_sessions_on_login: false },
               with_settings: { autologin: 1 } do
  let(:old_password) { "OldPassword!123" }
  let(:new_password) { "NewPassword!456" }
  let(:user) { create(:user, password: old_password, password_confirmation: old_password) }

  def login_browser(account, password, remember_me:)
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    browser.host! Setting.host_name
    browser.post "/login", params: {
      username: account.login,
      password:,
      autologin: remember_me ? "1" : "0"
    }
    5.times do
      break unless browser.response.redirect?

      browser.follow_redirect!
    end
    expect(browser.request.session[:user_id]).to eq(account.id)
    browser
  end

  it "revokes other sessions and autologin cookies when the user changes the password" do
    previous = login_browser(user, old_password, remember_me: true)
    current = login_browser(user, old_password, remember_me: false)
    previous_session_id = previous.request.session.id.private_id

    expect(Token::AutoLogin.where(user:).count).to eq(1)
    expect(Sessions::UserSession.for_user(user).count).to eq(2)

    current.patch "/api/v3/users/me",
                  params: { password: new_password, currentPassword: old_password },
                  headers: { "Sec-Fetch-Site" => "same-origin" },
                  as: :json

    expect(current.response).to have_http_status(:ok)
    expect(user.reload.check_password?(new_password)).to be true
    expect(Sessions::UserSession.find_by(session_id: previous_session_id)).to be_nil
    expect(Token::AutoLogin.where(user:)).to be_empty

    current.get "/my/account"
    expect(current.response).to have_http_status(:ok)
    expect(current.request.session[:user_id]).to eq(user.id)

    previous.get "/my/account"
    expect(previous.request.session[:user_id]).to be_nil
    expect(previous.response.location).to include("/login")
  end

  it "revokes the user's sessions and autologin cookies when an admin sets the password" do
    admin = create(:admin, password: old_password, password_confirmation: old_password)
    previous = login_browser(user, old_password, remember_me: true)
    admin_browser = login_browser(admin, old_password, remember_me: false)
    previous_session_id = previous.request.session.id.private_id

    admin_browser.patch "/api/v3/users/#{user.id}",
                        params: { password: new_password },
                        headers: { "Sec-Fetch-Site" => "same-origin" },
                        as: :json

    expect(admin_browser.response).to have_http_status(:ok)
    expect(user.reload.check_password?(new_password)).to be true
    expect(admin_browser.request.session[:user_id]).to eq(admin.id)
    expect(Sessions::UserSession.find_by(session_id: previous_session_id)).to be_nil
    expect(Token::AutoLogin.where(user:)).to be_empty
    expect(Sessions::UserSession.for_user(admin)).to exist

    previous.get "/my/account"
    expect(previous.request.session[:user_id]).to be_nil
    expect(previous.response.location).to include("/login")
  end
end
