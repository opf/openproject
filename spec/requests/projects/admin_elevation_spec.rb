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

RSpec.describe "Elevating admin privileges in a project",
               :skip_csrf,
               type: :rails_request,
               with_flag: { admin_privilege_elevation: true } do
  shared_let(:password) { "UserPassword!123" }
  shared_let(:admin) { create(:admin, password:, password_confirmation: password) }
  shared_let(:project) { create(:project, public: false) }

  let(:user) { admin }
  let(:browser) do
    ActionDispatch::Integration::Session.new(Rails.application).tap { it.host! Setting.host_name }
  end
  let(:session_id) { browser.request.session.id.private_id }

  before do
    browser.post "/login", params: { username: user.login, password: }
    5.times do
      break unless browser.response.redirect?

      browser.follow_redirect!
    end
  end

  describe "GET new" do
    def get_dialog
      browser.get "/projects/#{project.identifier}/admin_elevation/new",
                  headers: { "Accept" => "text/vnd.turbo-stream.html" }
      browser.response
    end

    it "renders the elevate dialog", :aggregate_failures do
      expect(get_dialog).to have_http_status(:ok)
      expect(browser.response.body).to include('data-test-selector="admin-elevation-dialog"')
    end

    context "for a regular user" do
      let(:user) { create(:user, password:, password_confirmation: password) }

      it "is forbidden" do
        expect(get_dialog).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST create" do
    let(:include_subprojects) { "0" }
    let(:back_url) { "/projects/#{project.identifier}/settings/general" }

    def elevate
      browser.post "/projects/#{project.identifier}/admin_elevation",
                   params: { back_url:, admin_elevation: { include_subprojects: } }
      browser.response
    end

    it "elevates the admin in the project for the session", :aggregate_failures do
      expect { elevate }.to change(AdminElevationSession, :count).by(1)

      expect(AdminElevationSession.last).to have_attributes(user: admin,
                                                            project:,
                                                            session_id:,
                                                            include_subprojects: false,
                                                            confirmed_with: "confirmation")
    end

    it "redirects back", :aggregate_failures do
      expect(elevate).to have_http_status(:see_other)
      expect(browser.response.location).to end_with(back_url)
    end

    it "grants access to the project settings afterwards" do
      elevate
      browser.get back_url

      expect(browser.response).to have_http_status(:ok)
    end

    context "with subprojects included" do
      let(:include_subprojects) { "1" }

      it "elevates the admin including the subprojects" do
        elevate

        expect(AdminElevationSession.last.include_subprojects).to be true
      end
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "does not elevate the admin", :aggregate_failures do
        expect { elevate }.not_to change(AdminElevationSession, :count)

        browser.follow_redirect!
        expect(browser.response.body).to include(I18n.t("activerecord.errors.messages.feature_disabled").delete_suffix("."))
      end
    end

    context "for a regular user" do
      let(:user) { create(:user, password:, password_confirmation: password) }

      it "is forbidden without elevating", :aggregate_failures do
        expect { elevate }.not_to change(AdminElevationSession, :count)
        expect(browser.response).to have_http_status(:forbidden)
      end
    end
  end
end
