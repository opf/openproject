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

require "spec_helper"

RSpec.describe "Changing the own email via PATCH /api/v3/users/me",
               with_settings: { user_can_change_email: true, autologin: 1 } do
  include API::V3::Utilities::PathHelper

  let(:password) { "Password!123456" }
  let(:user) { create(:user, mail: "old@example.org", password:, password_confirmation: password) }
  let!(:recovery_token) { create(:recovery_token, user:) }
  let!(:autologin_token) { create(:autologin_token, user:) }
  let!(:user_session) { create(:user_session, user:) }

  before do
    login_as(user)
    header "Content-Type", "application/json"
  end

  it "rejects the change without the current password" do
    patch api_v3_paths.user("me"), { email: "new@example.org" }.to_json

    expect(last_response).to have_http_status(:unprocessable_content)
    expect(user.reload.mail).to eq("old@example.org")
  end

  it "rejects the change with a wrong current password" do
    patch api_v3_paths.user("me"), { email: "new@example.org", currentPassword: "wrong" }.to_json

    expect(last_response).to have_http_status(:unprocessable_content)
    expect(user.reload.mail).to eq("old@example.org")
  end

  it "changes the email with the current password and ends all access" do
    patch api_v3_paths.user("me"), { email: "new@example.org", currentPassword: password }.to_json

    expect(last_response).to have_http_status(:ok)
    expect(user.reload.mail).to eq("new@example.org")
    expect(Token::Recovery.where(user:)).to be_empty
    expect(Token::AutoLogin.where(user:)).to be_empty
    expect(Sessions::UserSession.for_user(user)).to be_empty
  end

  it "keeps all access when only the name changes" do
    patch api_v3_paths.user("me"), { firstName: "Renamed" }.to_json

    expect(last_response).to have_http_status(:ok)
    expect(Token::Recovery.where(user:)).to exist
    expect(Token::AutoLogin.where(user:)).to exist
    expect(Sessions::UserSession.for_user(user)).to exist
  end

  context "when password confirmation is disabled", with_config: { internal_password_confirmation: false } do
    it "changes the email without the current password" do
      patch api_v3_paths.user("me"), { email: "new@example.org" }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(user.reload.mail).to eq("new@example.org")
    end
  end

  context "as an admin" do
    let(:user) { create(:admin, mail: "old@example.org", password:, password_confirmation: password) }

    it "rejects the change without the current password" do
      patch api_v3_paths.user("me"), { email: "new@example.org" }.to_json

      expect(last_response).to have_http_status(:unprocessable_content)
      expect(user.reload.mail).to eq("old@example.org")
    end

    it "changes the email with the current password" do
      patch api_v3_paths.user("me"), { email: "new@example.org", currentPassword: password }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(user.reload.mail).to eq("new@example.org")
    end
  end
end
