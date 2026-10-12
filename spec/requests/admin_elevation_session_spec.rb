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

RSpec.describe "Admin privilege elevation for Rails requests",
               :skip_csrf,
               type: :rails_request,
               with_flag: { admin_privilege_elevation: true } do
  shared_let(:password) { "AdminPassword!123" }
  shared_let(:admin) { create(:admin, password:, password_confirmation: password) }
  shared_let(:project) { create(:project, public: false) }

  let(:browser) do
    ActionDispatch::Integration::Session.new(Rails.application).tap { it.host! Setting.host_name }
  end

  context "when authenticated by the session" do
    let(:session_id) { browser.request.session.id.private_id }
    let(:project_settings_path) { "/projects/#{project.identifier}/settings/general" }

    def get_project_settings
      browser.get project_settings_path
      browser.response
    end

    before do
      browser.post "/login", params: { username: admin.login, password: }
      5.times do
        break unless browser.response.redirect?

        browser.follow_redirect!
      end
    end

    context "without an elevation" do
      it "denies access to the project settings" do
        expect(get_project_settings).to have_http_status(:forbidden)
      end

      it "shows the elevation banner on the project overview", :aggregate_failures do
        browser.get "/projects/#{project.identifier}"

        expect(browser.response).to have_http_status(:ok)
        expect(browser.response.body).to include('data-test-selector="admin-elevation-banner"')
      end
    end

    context "with an active elevation for the project in the session for the overview" do
      before { create(:admin_elevation_session, user: admin, project:, session_id:) }

      it "does not show the elevation banner on the project overview", :aggregate_failures do
        browser.get "/projects/#{project.identifier}"

        expect(browser.response).to have_http_status(:ok)
        expect(browser.response.body).not_to include('data-test-selector="admin-elevation-banner"')
      end
    end

    context "with an active elevation for the project in the session" do
      let!(:elevation_session) do
        create(:admin_elevation_session, user: admin, project:, session_id:, last_used_at: 10.minutes.ago)
      end

      it "grants access to the project settings" do
        expect(get_project_settings).to have_http_status(:ok)
      end

      it "moves the last use of the elevation to now" do
        freeze_time do
          get_project_settings

          expect(elevation_session.reload.last_used_at).to eq(Time.current)
        end
      end

      context "with an active elevation for another project in the session" do
        let!(:other_elevation_session) do
          create(:admin_elevation_session, user: admin, project: create(:project), session_id:,
                                           last_used_at: 10.minutes.ago)
        end

        it "does not move the last use of the other elevation" do
          expect { get_project_settings }.not_to change { other_elevation_session.reload.last_used_at }
        end
      end
    end

    context "with an active elevation including subprojects for the parent project in the session" do
      let(:project_settings_path) { "/projects/#{subproject.identifier}/settings/general" }
      let(:subproject) { create(:project, parent: project, public: false) }
      let!(:elevation_session) do
        create(:admin_elevation_session, user: admin, project:, session_id:, include_subprojects: true,
                                         last_used_at: 10.minutes.ago)
      end

      it "grants access to the settings of the subproject" do
        expect(get_project_settings).to have_http_status(:ok)
      end

      it "moves the last use of the elevation to now" do
        freeze_time do
          get_project_settings

          expect(elevation_session.reload.last_used_at).to eq(Time.current)
        end
      end
    end

    context "with an active elevation for the project in the session of a user that is no longer an admin" do
      before do
        create(:admin_elevation_session, user: admin, project:, session_id:)
        User.where(id: admin.id).update_all(admin: false)
      end

      it "does not find the project like for any other non-member" do
        expect(get_project_settings).to have_http_status(:not_found)
      end
    end

    context "with an active elevation for the project in another session" do
      before { create(:admin_elevation_session, user: admin, project:, session_id: "other") }

      it "denies access to the project settings" do
        expect(get_project_settings).to have_http_status(:forbidden)
      end
    end

    context "with an ended elevation for the project in the session" do
      before { create(:admin_elevation_session, user: admin, project:, session_id:, ended_at: Time.current) }

      it "denies access to the project settings" do
        expect(get_project_settings).to have_http_status(:forbidden)
      end
    end

    context "with an idle elevation for the project in the session" do
      before { create(:admin_elevation_session, user: admin, project:, session_id:, last_used_at: 1.day.ago) }

      it "denies access to the project settings" do
        expect(get_project_settings).to have_http_status(:forbidden)
      end
    end

    context "with an active elevation for another project in the session" do
      before { create(:admin_elevation_session, user: admin, project: create(:project), session_id:) }

      it "denies access to the project settings" do
        expect(get_project_settings).to have_http_status(:forbidden)
      end
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "grants access to the project settings without an elevation" do
        expect(get_project_settings).to have_http_status(:ok)
      end
    end
  end

  context "when authenticated by an RSS key" do
    let(:rss_token) { create(:rss_token, user: admin) }

    def get_news_feed
      browser.get "/projects/#{project.identifier}/news.atom", params: { key: rss_token.plain_value }
      browser.response
    end

    it "grants access to the news feed without an elevation" do
      expect(get_news_feed).to have_http_status(:ok)
    end

    context "with the feature flag inactive", with_flag: { admin_privilege_elevation: false } do
      it "grants access to the news feed without an elevation" do
        expect(get_news_feed).to have_http_status(:ok)
      end
    end
  end
end
