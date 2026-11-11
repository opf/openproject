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

RSpec.describe "API v3 notification summary",
               content_type: :json,
               with_flag: { progressive_web_app: true } do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:author) { create(:user, firstname: "Ada", lastname: "Lovelace") }
  shared_let(:work_package) { create(:work_package, project:, subject: "Fix the build") }

  let(:path) { api_v3_paths.notification_summary }
  let(:json) { JSON.parse(last_response.body) }

  def notify(recipient: user, resource: work_package, journal: nil)
    create(:notification, recipient:, resource:, reason: :mentioned, actor: author, journal:)
  end

  def tag_for(recipient)
    "openproject-#{recipient.id}-wp-#{work_package.id}"
  end

  describe "signed-in user" do
    current_user { user }

    it "describes nothing unread as a zero count" do
      header "Accept", "application/json"
      get path

      expect(last_response).to have_http_status(:ok)
      expect(last_response.headers["Cache-Control"]).to include("no-store")
      expect(last_response.body)
        .to be_json_eql({ _type: "NotificationSummary",
                          count: 0,
                          _links: { self: { href: path } } }.to_json)
    end

    it "describes a single unread notification as one work package group" do
      notify(journal: work_package.journals.sole)

      get path

      expect(last_response.body).to be_json_eql(1).at_path("count")
      expect(last_response.body).not_to have_json_path("more")
      expect(json["groups"]).to contain_exactly(
        include("tag" => tag_for(user),
                "count" => 1,
                "revision" => match(/\A\d+:\d+\z/),
                "title" => "Ada Lovelace mentioned you",
                "body" => "#{work_package.formatted_id}: Fix the build",
                "url" => "/notifications/details/#{work_package.id}/activity")
      )
    end

    it "points at the notification center when more work packages are unread than listed" do
      create_list(:work_package, 6, project:).each { notify(resource: it) }

      get path

      expect(json["more"]).to include("count" => 1, "url" => "/notifications")
    end

    context "when served under a path prefix", with_config: { rails_relative_url_root: "/openproject" } do
      it "prefixes the group and overflow urls" do
        create_list(:work_package, 6, project:).each { notify(resource: it) }

        get "/api/v3/notifications/summary", {}, "SCRIPT_NAME" => "/openproject"

        expect(json.dig("groups", 0, "url")).to start_with("/openproject/notifications/details/")
        expect(json.dig("more", "url")).to eq("/openproject/notifications")
      end
    end

    context "with the feature flag off", with_flag: { progressive_web_app: false } do
      before { get path }

      it_behaves_like "not found"
    end

    context "when push notifications are disabled", with_settings: { web_push_enabled: false } do
      it "still serves the summary" do
        get path

        expect(last_response).to have_http_status(:ok)
      end
    end

    it "serves only the signed-in user's notifications" do
      notify
      notify(recipient: author)

      get path

      expect(json["count"]).to eq(1)
      expect(json["groups"].pluck("tag")).to eq([tag_for(user)])
    end
  end

  describe "locked user" do
    current_user { create(:user, status: :locked) }

    before { get path }

    it_behaves_like "unauthenticated access"
  end

  describe "anonymous user" do
    current_user { User.anonymous }

    context "when login is required", with_settings: { login_required: true } do
      before { get path }

      it_behaves_like "unauthenticated access"
    end

    context "when login is not required", with_settings: { login_required: false } do
      before { get path }

      it_behaves_like "unauthenticated access"

      it "forbids caching the response" do
        expect(last_response.headers["Cache-Control"]).to include("no-store")
      end
    end
  end
end
