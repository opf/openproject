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

RSpec.describe "PWA push notification", type: :rails_request, with_flag: { progressive_web_app: true } do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:author) { create(:user, firstname: "Ada", lastname: "Lovelace") }
  shared_let(:work_package) { create(:work_package, project:, subject: "Fix the build") }

  let(:json) { response.parsed_body }

  def notify(reason: :mentioned, resource: work_package, journal: nil, **)
    create(:notification, recipient: user, resource:, reason:, actor: author, journal:, **)
  end

  def wp_tag(work_package)
    "openproject-#{user.id}-wp-#{work_package.id}"
  end

  context "without a session" do
    it "returns 401 instead of redirecting" do
      get "/push-notification"

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  context "without a session and without required login", with_settings: { login_required: false, web_push_enabled: true } do
    it "still returns 401" do
      get "/push-notification"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with credentials other than a session", with_settings: { web_push_enabled: true } do
    let(:password) { "Sup3rS3cret!pass" }
    let(:json_headers) { { "Accept" => "application/json" } }
    let(:password_user) { create(:user, password:, password_confirmation: password) }

    it "returns 401 for a valid API key" do
      token = create(:api_token, user:)

      get "/push-notification",
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("apikey", token.plain_value) }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for HTTP Basic user credentials" do
      get "/push-notification",
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(password_user.login, password) }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a valid SSO header without a session" do
      allow(OpenProject::Configuration)
        .to receive(:auth_source_sso).and_return(header: "X-Remote-User", optional: true)
      sso_user = create(:user, login: "sso_user", ldap_auth_source: create(:ldap_auth_source))

      get "/push-notification", headers: { "X-Remote-User" => sso_user.login }

      expect(response).to have_http_status(:unauthorized)
      expect(Sessions::UserSession.for_user(sso_user.id)).to be_empty
    end

    it "returns 401 for a valid autologin cookie instead of starting a session",
       with_settings: { autologin: 1 } do
      token = create(:autologin_token, user:)
      cookies[OpenProject::Configuration["autologin_cookie_name"]] = token.plain_value

      get "/push-notification", headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(Sessions::UserSession.for_user(user.id)).to be_empty
    end
  end

  context "with a stale session and other credentials", :skip_csrf,
          with_settings: { web_push_enabled: true, autologin: 1 } do
    let(:password) { "Sup3rS3cret!pass" }
    let(:password_user) { create(:user, password:, password_confirmation: password) }

    it "returns 401 and starts no session when the session user is locked" do
      allow(OpenProject::Configuration)
        .to receive(:auth_source_sso).and_return(header: "X-Remote-User", optional: true)
      host! Setting.host_name
      post "/login", params: { username: password_user.login, password: }
      follow_redirect! while response.redirect?
      token = create(:autologin_token, user: password_user)
      cookies[OpenProject::Configuration["autologin_cookie_name"]] = token.plain_value
      password_user.lock!
      sessions_before = Sessions::UserSession.for_user(password_user.id).count

      get "/push-notification",
          headers: { "Accept" => "application/json", "X-Remote-User" => password_user.login }

      expect(response).to have_http_status(:unauthorized)
      expect(Sessions::UserSession.for_user(password_user.id).count).to eq(sessions_before)
    end
  end

  context "with a signed-in browser session", :skip_csrf,
          with_settings: { web_push_enabled: true, session_ttl_enabled?: true, session_ttl: "120" } do
    let(:password) { "Sup3rS3cret!pass" }
    let(:password_user) { create(:user, password:, password_confirmation: password) }
    let(:json_headers) { { "Accept" => "application/json" } }

    before do
      host! Setting.host_name
      post "/login", params: { username: password_user.login, password: }
      follow_redirect! while response.redirect?
      get "/push-notification", headers: json_headers
    end

    it "does not extend the session on wake-ups" do
      last_seen = request.session[:updated_at]

      travel_to(10.minutes.from_now) { get "/push-notification", headers: json_headers }

      expect(response).to have_http_status(:ok)
      expect(request.session[:updated_at]).to eq(last_seen)
    end

    it "does not touch the session row on wake-ups" do
      sessions = Sessions::UserSession.for_user(password_user.id)
      sessions.update_all(updated_at: 1.day.ago)
      touched_at = sessions.sole.updated_at

      travel_to(10.minutes.from_now) { get "/push-notification", headers: json_headers }

      expect(response).to have_http_status(:ok)
      expect(sessions.sole.updated_at).to eq(touched_at)
    end

    it "returns 401 instead of redirecting once the session has idled past its lifetime" do
      travel_to(3.hours.from_now) { get "/push-notification", headers: json_headers }

      expect(response).to have_http_status(:unauthorized)
    end

    it "keeps the user's other sessions when this one expires on a wake-up" do
      allow(OpenProject::Configuration).to receive(:drop_old_sessions_on_logout?).and_return(true)
      current_session_id = Sessions::UserSession.for_user(password_user.id).sole.session_id
      other_session = create(:user_session, user: password_user)

      travel_to(3.hours.from_now) { get "/push-notification", headers: json_headers }

      expect(response).to have_http_status(:unauthorized)
      expect(Sessions::UserSession.where(session_id: other_session.session_id)).to exist
      expect(Sessions::UserSession.where(session_id: current_session_id)).not_to exist
    end
  end

  context "with a signed-in browser session behind an SSO header", :skip_csrf, with_settings: { web_push_enabled: true } do
    let(:password) { "Sup3rS3cret!pass" }
    let(:password_user) { create(:user, password:, password_confirmation: password) }
    let(:sso_config) { { header: "X-Remote-User" } }
    let(:headers) { { "Accept" => "application/json" } }

    before do
      host! Setting.host_name
      post "/login", params: { username: password_user.login, password: }
      follow_redirect! while response.redirect?
      allow(OpenProject::Configuration).to receive(:auth_source_sso).and_return(sso_config)
    end

    it "serves the session user when the SSO header names them" do
      get "/push-notification", headers: headers.merge("X-Remote-User" => password_user.login)

      expect(response).to have_http_status(:ok)
      expect(json).to eq("count" => 0)
    end

    it "returns 401 when the SSO header names another user" do
      other = create(:user)
      session_ids = Sessions::UserSession.for_user(password_user.id).pluck(:session_id)

      get "/push-notification", headers: headers.merge("X-Remote-User" => other.login)

      expect(response).to have_http_status(:unauthorized)
      expect(Sessions::UserSession.for_user(password_user.id).pluck(:session_id)).to eq(session_ids)
      expect(Sessions::UserSession.for_user(other.id)).to be_empty
    end

    it "returns 401 when the SSO header is missing and not optional" do
      get "/push-notification", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    context "when the SSO header carries an invalid secret" do
      let(:sso_config) { { header: "X-Remote-User", secret: "s3cr3t" } }

      it "returns 401 when the SSO header carries an invalid secret" do
        get "/push-notification", headers: headers.merge("X-Remote-User" => "#{password_user.login}:wrong")

        expect(response).to have_http_status(:unauthorized)
      end

      context "when the SSO header is also optional" do
        let(:sso_config) { { header: "X-Remote-User", secret: "s3cr3t", optional: true } }

        it "still returns 401" do
          get "/push-notification", headers: headers.merge("X-Remote-User" => "#{password_user.login}:wrong")

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "when the SSO header is optional" do
      let(:sso_config) { { header: "X-Remote-User", optional: true } }

      it "serves the session user without a header" do
        get "/push-notification", headers: headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "with the feature flag off", with_flag: { progressive_web_app: false } do
    it "is not routed" do
      login_as user

      expect { get "/push-notification" }.to raise_error(ActionController::RoutingError)
    end
  end

  context "with a session" do
    before { login_as user }

    it "does not route a format suffix" do
      expect { get "/push-notification.json" }.to raise_error(ActionController::RoutingError)
    end

    context "when push notifications are disabled", with_settings: { web_push_enabled: false } do
      it "returns 404" do
        get "/push-notification"

        expect(response).to have_http_status(:not_found)
        expect(response.headers["Cache-Control"]).to include("no-store")
      end
    end

    context "when push notifications are enabled", with_settings: { web_push_enabled: true } do
      it "is never cached" do
        get "/push-notification"

        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "describes a single unread notification as one work package group" do
        notification = notify(journal: work_package.journals.sole)

        get "/push-notification"

        expect(json).to eq(
          "count" => 1,
          "groups" => [{ "tag" => wp_tag(work_package),
                         "count" => 1,
                         "revision" => "#{notification.id}:#{(notification.journal.reload.updated_at.to_f * 1000).to_i}",
                         "title" => "Ada Lovelace mentioned you",
                         "body" => "#{work_package.formatted_id}: Fix the build",
                         "url" => "/notifications/details/#{work_package.id}/activity" }],
          "more" => nil
        )
      end

      context "when served under a path prefix", with_config: { rails_relative_url_root: "/openproject" } do
        it "prefixes the group and overflow urls" do
          create_list(:work_package, 6, project:).each { notify(resource: it) }

          get "/push-notification", env: { "SCRIPT_NAME" => "/openproject" }

          expect(json.dig("groups", 0, "url")).to start_with("/openproject/notifications/details/")
          expect(json.dig("more", "url")).to eq("/openproject/notifications")
        end
      end
    end
  end
end
