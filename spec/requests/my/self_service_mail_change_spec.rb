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

RSpec.describe "Changing the own email on /my/settings",
               :skip_csrf,
               type: :rails_request,
               with_config: { internal_password_confirmation: true },
               with_settings: { user_can_change_email: true } do
  let(:password) { "Password!123456" }
  let(:user) do
    create(:user, mail: "old@example.org", language: "en", password:, password_confirmation: password)
  end

  before do
    post "/login", params: { username: user.login, password: }
    follow_redirect! while response.redirect?
  end

  it "does not change the email" do
    patch "/my/settings", params: { user: { mail: "new@example.org" } }

    expect(user.reload.mail).to eq("old@example.org")
  end

  it "still changes the language" do
    patch "/my/settings", params: { user: { language: "de" } }

    expect(user.reload.language).to eq("de")
  end

  context "when using the onboarding settings" do
    it "does not change the email" do
      patch "/user_settings", params: { user: { mail: "new@example.org" } }, headers: { "Referer" => "/" }

      expect(user.reload.mail).to eq("old@example.org")
    end

    it "still changes the language" do
      patch "/user_settings", params: { user: { language: "de" } }, headers: { "Referer" => "/" }

      expect(user.reload.language).to eq("de")
    end
  end
end
