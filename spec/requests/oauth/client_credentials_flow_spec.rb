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

RSpec.describe "OAuth client credentials flow" do
  include Rack::Test::Methods

  let!(:application) { create(:oauth_application, client_credentials_user_id: user_id, name: "Cool API app!") }
  let(:client_secret) { application.plaintext_secret }

  let(:access_token) do
    response = post("/oauth/token",
                    grant_type: "client_credentials", scope: "api_v3", client_id: application.uid, client_secret:)

    expect(response).to be_successful
    body = JSON.parse(response.body)
    body["access_token"]
  end

  let(:make_request) do
    # Perform request with it
    headers = { "HTTP_CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{access_token}" }
    get "/api/v3", {}, headers
  end

  subject { JSON.parse(make_request.body) }

  describe "when application provides client credentials impersonator" do
    let(:user) { create(:user) }
    let(:user_id) { user.id }

    it "allows client credential flow as the user" do
      expect(make_request).to be_successful
      expect(subject.dig("_links", "user", "href")).to eq("/api/v3/users/#{user.id}")
    end
  end

  describe "when application does not provide client credential impersonator" do
    let(:user_id) { nil }

    before do
      make_request
    end

    context "when login_required", with_settings: { login_required: true } do
      it_behaves_like "unauthenticated access"
    end

    context "when not login_required", with_settings: { login_required: false } do
      it "allows client credential flow as the anonymous user" do
        expect(make_request).to be_successful
        expect(subject.dig("_links", "user", "href")).to be_nil
      end
    end
  end
end
