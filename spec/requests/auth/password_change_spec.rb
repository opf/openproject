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

RSpec.describe "Password change session revocation",
               :skip_csrf,
               type: :rails_request,
               with_config: { drop_old_sessions_on_login: false },
               with_settings: { autologin: 1 } do
  let(:old_password) { "OldPassword!123" }
  let(:new_password) { "NewPassword!456" }
  let(:user) { create(:user, password: old_password, password_confirmation: old_password) }

  def login_browser(remember_me:)
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    browser.host! Setting.host_name
    browser.post "/login", params: {
      username: user.login,
      password: old_password,
      autologin: remember_me ? "1" : "0"
    }
    5.times do
      break unless browser.response.redirect?

      browser.follow_redirect!
    end
    expect(browser.request.session[:user_id]).to eq(user.id)
    browser
  end

  it "revokes the other browser session without remember-me" do
    browser_a = login_browser(remember_me: true)
    browser_b = login_browser(remember_me: false)

    old_b_id = browser_b.request.session.id.private_id
    expect(Token::AutoLogin.where(user:).count).to eq(1)
    expect(Sessions::UserSession.for_user(user).count).to eq(2)
    browser_a.post "/my/change_password", params: {
      password: old_password,
      new_password: new_password,
      new_password_confirmation: new_password
    }
    expect(user.reload.check_password?(new_password)).to be true
    expect(browser_a.request.session[:user_id]).to eq(user.id)
    expect(Sessions::UserSession.find_by(session_id: old_b_id)).to be_nil

    browser_a.get "/my/account"
    expect(browser_a.response.status).to eq(200)
    expect(browser_a.request.session[:user_id]).to eq(user.id)
    expect(Token::AutoLogin.where(user:)).to be_empty

    browser_b.get "/my/account"
    expect(browser_b.request.session[:user_id]).to be_nil
    expect(browser_b.response.location).to include("/login")
  end

  it "revokes the other browser session with remember-me" do
    browser_a = login_browser(remember_me: true)
    browser_b = login_browser(remember_me: true)

    old_b_id = browser_b.request.session.id.private_id
    expect(Token::AutoLogin.where(user:).count).to eq(2)
    expect(Sessions::UserSession.for_user(user).count).to eq(2)
    browser_a.post "/my/change_password", params: {
      password: old_password,
      new_password: new_password,
      new_password_confirmation: new_password
    }
    expect(user.reload.check_password?(new_password)).to be true
    expect(browser_a.request.session[:user_id]).to eq(user.id)
    expect(Sessions::UserSession.find_by(session_id: old_b_id)).to be_nil

    browser_a.get "/my/account"
    expect(browser_a.response.status).to eq(200)
    expect(browser_a.request.session[:user_id]).to eq(user.id)
    expect(Token::AutoLogin.where(user:)).to be_empty

    browser_b.get "/my/account"
    expect(browser_b.request.session[:user_id]).to be_nil
    expect(browser_b.response.location).to include("/login")
  end
end
