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

  shared_context "with a relative url root" do
    around do |example|
      previous = OpenProject::Configuration["rails_relative_url_root"]
      OpenProject::Configuration["rails_relative_url_root"] = "/openproject"
      example.run
    ensure
      OpenProject::Configuration["rails_relative_url_root"] = previous
    end
  end

  def notify(reason: :mentioned, resource: work_package, **)
    create(:notification, recipient: user, resource:, reason:, actor: author, **)
  end

  context "without a session" do
    it "answers 401 instead of redirecting" do
      get "/push-notification"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "without a session and without required login", with_settings: { login_required: false, web_push_enabled: true } do
    it "still answers 401" do
      get "/push-notification"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with credentials other than a session", with_settings: { web_push_enabled: true } do
    let(:password) { "Sup3rS3cret!pass" }
    let(:json_headers) { { "Accept" => "application/json" } }
    let(:password_user) { create(:user, password:, password_confirmation: password) }

    it "answers 401 for a valid API key" do
      token = create(:api_token, user:)

      get "/push-notification",
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("apikey", token.plain_value) }

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 401 for HTTP Basic user credentials" do
      get "/push-notification",
          headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(password_user.login, password) }

      expect(response).to have_http_status(:unauthorized)
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

    it "answers 401 instead of redirecting once the session has idled past its lifetime" do
      travel_to(3.hours.from_now) { get "/push-notification", headers: json_headers }

      expect(response).to have_http_status(:unauthorized)
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
      it "answers 404" do
        get "/push-notification"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when push notifications are enabled", with_settings: { web_push_enabled: true } do
      it "is never cached" do
        get "/push-notification"

        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "reports only the count when everything is read" do
        notify(read_ian: true)

        get "/push-notification"

        expect(response).to have_http_status(:ok)
        expect(json).to eq("count" => 0)
      end

      it "describes a single unread notification and links to its work package" do
        notify

        get "/push-notification"

        expect(json).to eq("count" => 1,
                           "title" => "Ada Lovelace mentioned you",
                           "body" => "##{work_package.id}: Fix the build",
                           "url" => "/work_packages/#{work_package.id}")
      end

      it "summarises several unread notifications and links to the notification centre" do
        notify(reason: :commented, created_at: 3.minutes.ago)
        notify(reason: :assigned, created_at: 2.minutes.ago)
        notify(reason: :mentioned, created_at: 1.minute.ago)

        get "/push-notification"

        expect(json).to eq("count" => 3,
                           "title" => "3 unread notifications",
                           "body" => "Ada Lovelace mentioned you: ##{work_package.id} Fix the build",
                           "url" => "/notifications")
      end

      it "words date alerts without an actor" do
        create(:notification, recipient: user, resource: work_package, reason: :date_alert_due_date, actor: nil)

        get "/push-notification"

        expect(json["title"]).to eq("Due date alert")
      end

      it "names a deleted actor" do
        notify(actor: nil)

        get "/push-notification"

        expect(json["title"]).to eq("Deleted user mentioned you")
      end

      it "uses the date alert headline when the latest of several has no actor" do
        notify(reason: :commented, created_at: 2.minutes.ago)
        create(:notification, recipient: user, resource: work_package, reason: :date_alert_due_date,
                              actor: nil, created_at: 1.minute.ago)

        get "/push-notification"

        expect(json["body"]).to start_with("Due date alert: ")
      end

      it "does not count mail-only notifications" do
        notify(read_ian: nil)

        get "/push-notification"

        expect(json).to eq("count" => 0)
      end

      context "when served under a path prefix" do
        include_context "with a relative url root"

        it "prefixes the single notification url" do
          notify

          get "/push-notification", env: { "SCRIPT_NAME" => "/openproject" }

          expect(json["url"]).to start_with("/openproject/")
        end

        it "prefixes the summary url" do
          notify(reason: :commented)
          notify

          get "/push-notification", env: { "SCRIPT_NAME" => "/openproject" }

          expect(json["url"]).to eq("/openproject/notifications")
        end
      end

      it "excludes notifications on work packages the user cannot see" do
        hidden = create(:work_package, project: create(:project))
        notify(resource: hidden)

        get "/push-notification"

        expect(json).to eq("count" => 0)
      end
    end
  end
end
