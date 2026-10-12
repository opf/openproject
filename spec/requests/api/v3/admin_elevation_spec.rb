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

RSpec.describe "API v3 admin privilege elevation",
               :skip_csrf,
               type: :rails_request,
               with_flag: { admin_privilege_elevation: true } do
  shared_let(:password) { "AdminPassword!123" }
  shared_let(:admin) { create(:admin, password:, password_confirmation: password) }
  shared_let(:project) { create(:project, public: false) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:browser) { ActionDispatch::Integration::Session.new(Rails.application) }
  let(:work_package_path) { "/api/v3/work_packages/#{work_package.id}" }

  def get_work_package(headers: {})
    browser.get work_package_path, headers: headers
    browser.response
  end

  context "when authenticated by the session" do
    let(:session_id) { browser.request.session.id.private_id }

    before do
      browser.host! Setting.host_name
      browser.post "/login", params: { username: admin.login, password: }
      5.times do
        break unless browser.response.redirect?

        browser.follow_redirect!
      end
    end

    context "without an elevation" do
      it "does not find the work package" do
        expect(get_work_package).to have_http_status(:not_found)
      end
    end

    context "with an active elevation for the project in the session" do
      before { create(:admin_elevation_session, user: admin, project:, session_id:) }

      it "returns the work package" do
        expect(get_work_package).to have_http_status(:ok)
      end
    end

    context "with an active elevation for the project in another session" do
      before { create(:admin_elevation_session, user: admin, project:, session_id: "other") }

      it "does not find the work package" do
        expect(get_work_package).to have_http_status(:not_found)
      end
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "returns the work package without an elevation" do
        expect(get_work_package).to have_http_status(:ok)
      end
    end
  end

  context "when authenticated by an API key", with_settings: { api_tokens_enabled: true } do
    let(:token) { create(:api_token, user: admin) }

    before { browser.host! Setting.host_name }

    it "returns the work package without an elevation" do
      expect(get_work_package(headers: { "Authorization" => "Bearer #{token.plain_value}" }))
        .to have_http_status(:ok)
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "returns the work package without an elevation" do
        expect(get_work_package(headers: { "Authorization" => "Bearer #{token.plain_value}" }))
          .to have_http_status(:ok)
      end
    end
  end
end
