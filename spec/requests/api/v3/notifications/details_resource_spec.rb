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

require "spec_helper"

RSpec.describe API::V3::Notifications::NotificationsAPI,
               "fetch notification details",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:resource) do
    create(:work_package,
           project:,
           start_date: Date.yesterday,
           due_date: Date.tomorrow)
  end
  shared_let(:milestone_resource) do
    create(:work_package,
           :is_milestone,
           project:,
           start_date: Date.tomorrow,
           due_date: Date.tomorrow)
  end
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages] })
  end

  let(:notification) { create(:notification, recipient:, resource:, reason:) }
  let(:milestone_notification) { create(:notification, recipient:, resource: milestone_resource, reason:) }
  let(:reason) { :date_alert_start_date }

  # We have 1 detail item at maximum, and the id is coming
  # from the detail's array index which is 0
  let(:detail_id) { 0 }
  let(:notification_detail_path) { api_v3_paths.notification_detail(notification.id, detail_id) }
  let(:send_request) do
    get notification_detail_path
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  before do
    login_as current_user
  end

  describe "recipient user" do
    let(:current_user) { recipient }

    context "for a non dateAlert notification" do
      let(:reason) { :mentioned }

      it "returns a 404 response" do
        send_request
        expect(last_response).to have_http_status(:not_found)
      end
    end

    context "for a start date alert notification" do
      let(:reason) { :date_alert_start_date }

      it "can get the notification details for a start date" do
        send_request
        expect(last_response.body)
          .to be_json_eql("startDate".to_json)
                .at_path("property")
        expect(last_response.body)
          .to be_json_eql(API::V3::Utilities::DateTimeFormatter.format_date(resource.start_date).to_json)
                .at_path("value")
        expect(last_response.body)
          .to be_json_eql(notification_detail_path.to_json)
                .at_path("_links/self/href")
        expect(last_response.body)
          .to be_json_eql("/api/v3/values/schemas/startDate".to_json)
                .at_path("_links/schema/href")
      end
    end

    context "for a due date alert notification" do
      let(:reason) { :date_alert_due_date }

      it "can get the notification details for a due date" do
        send_request
        expect(last_response.body)
          .to be_json_eql("dueDate".to_json)
                .at_path("property")
        expect(last_response.body)
          .to be_json_eql(API::V3::Utilities::DateTimeFormatter.format_date(resource.due_date).to_json)
                .at_path("value")
        expect(last_response.body)
          .to be_json_eql(notification_detail_path.to_json)
                .at_path("_links/self/href")
        expect(last_response.body)
          .to be_json_eql("/api/v3/values/schemas/dueDate".to_json)
                .at_path("_links/schema/href")
      end
    end

    context "for a start date alert notification with a milestone resource" do
      let(:notification) { milestone_notification }
      let(:reason) { :date_alert_start_date }

      it "can get the notification details for a start date" do
        send_request
        expect(last_response.body)
          .to be_json_eql("date".to_json)
                .at_path("property")
        expect(last_response.body)
          .to be_json_eql(API::V3::Utilities::DateTimeFormatter.format_date(resource.due_date).to_json)
                .at_path("value")
        expect(last_response.body)
          .to be_json_eql(notification_detail_path.to_json)
                .at_path("_links/self/href")
        expect(last_response.body)
          .to be_json_eql("/api/v3/values/schemas/date".to_json)
                .at_path("_links/schema/href")
      end
    end
  end

  describe "admin user" do
    current_user { build_stubbed(:admin) }

    before do
      send_request
    end

    it "returns a 404 response" do
      expect(last_response).to have_http_status(:not_found)
    end
  end

  describe "unauthorized user" do
    current_user { build_stubbed(:user) }

    before do
      send_request
    end

    it "returns a 404 response" do
      expect(last_response).to have_http_status(:not_found)
    end
  end
end
