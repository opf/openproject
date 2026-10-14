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
require "rack/test"

RSpec.describe API::V3::Notifications::NotificationsAPI,
               "create",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[documents work_package_tracking]) }
  shared_let(:document) { create(:document, project:) }
  shared_let(:caller_user) do
    create(:user,
           member_with_permissions: { project => %i[view_documents manage_documents] })
  end
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { project => %i[view_documents] })
  end

  let(:current_user) { caller_user }
  let(:reason) { "mentioned" }
  let(:resource_href) { api_v3_paths.document(document.id) }
  let(:recipient_href) { api_v3_paths.user(recipient.id) }
  let(:body) do
    {
      reason:,
      _links: {
        resource: { href: resource_href },
        recipient: { href: recipient_href }
      }
    }
  end
  let(:parsed_response) { JSON.parse(last_response.body) }

  let(:send_request) do
    post api_v3_paths.notifications, body.to_json
  end

  before do
    login_as current_user
  end

  shared_examples_for "no notification created" do
    it "responds with 204 and creates no notification" do
      expect { send_request }.not_to change(Notification, :count)

      expect(last_response).to have_http_status(:no_content)
      expect(last_response.body).to be_empty
    end
  end

  shared_examples_for "unprocessable" do |attribute|
    it "responds with 422 and creates no notification" do
      expect { send_request }.not_to change(Notification, :count)

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(parsed_response["errorIdentifier"])
        .to eq("urn:openproject-org:api:v3:errors:PropertyConstraintViolation")
      expect(parsed_response.dig("_embedded", "details", "attribute")).to eq(attribute)
    end
  end

  context "when mentioning a user in a document" do
    it "creates a mention notification and responds with a reduced representation" do
      expect { send_request }.to change(Notification, :count).by(1)

      expect(last_response).to have_http_status(:created)

      notification = Notification.last
      expect(parsed_response)
        .to eq("_type" => "Notification",
               "id" => notification.id,
               "_links" => {
                 "resource" => { "href" => api_v3_paths.document(document.id), "title" => document.title },
                 "recipient" => { "href" => api_v3_paths.user(recipient.id), "title" => recipient.name }
               })
      expect(parsed_response).not_to have_key("_embedded")
      expect(parsed_response["_links"]).not_to include("self", "readIAN", "unreadIAN")

      expect(notification).to have_attributes(recipient:,
                                              resource: document,
                                              actor: caller_user,
                                              reason: "mentioned",
                                              journal: nil,
                                              read_ian: false,
                                              mail_alert_sent: nil,
                                              mail_reminder_sent: nil)
    end
  end

  context "when the recipient has disabled mention notifications globally" do
    before do
      recipient.notification_settings.update_all(mentioned: false)
    end

    it_behaves_like "no notification created"
  end

  context "when the recipient has disabled mention notifications for the project" do
    before do
      create(:notification_setting, user: recipient, project:, mentioned: false)
    end

    it_behaves_like "no notification created"
  end

  context "when the recipient has disabled mention notifications globally but enabled them for the project" do
    before do
      recipient.notification_settings.update_all(mentioned: false)
      create(:notification_setting, user: recipient, project:, mentioned: true)
    end

    it "creates a notification" do
      expect { send_request }.to change(Notification, :count).by(1)

      expect(last_response).to have_http_status(:created)
    end
  end

  context "when mentioning oneself" do
    let(:recipient_href) { api_v3_paths.user(caller_user.id) }

    it_behaves_like "no notification created"
  end

  context "with a reason other than mentioned" do
    let(:reason) { "assigned" }

    it_behaves_like "unprocessable", "reason"
  end

  context "with an unknown reason" do
    let(:reason) { "foo" }

    it_behaves_like "unprocessable", "reason"
  end

  context "with a resource type not supporting mentions via the API (work package)" do
    let(:work_package) { create(:work_package, project:) }
    let(:resource_href) { api_v3_paths.work_package(work_package.id) }

    it_behaves_like "unprocessable", "resource"
  end

  context "with a resource href not pointing to a known resource type" do
    let(:resource_href) { api_v3_paths.user(recipient.id) }

    it_behaves_like "unprocessable", "resource"
  end

  context "with a malformed resource href" do
    let(:resource_href) { "/foo/bar" }

    it "responds with 422" do
      expect { send_request }.not_to change(Notification, :count)

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(parsed_response["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:ResourceTypeMismatch")
    end
  end

  context "with a workspace nested resource href" do
    let(:resource_href) { "/api/v3/workspaces/#{project.id}/documents/#{document.id}" }

    it_behaves_like "unprocessable", "resource"
  end

  context "with malformed links" do
    let(:body) { { reason:, _links: { resource: "foo", recipient: [] } } }

    it "responds with 422" do
      send_request

      expect(last_response).to have_http_status(:unprocessable_entity)
    end
  end

  context "with a recipient that does not exist" do
    let(:recipient_href) { api_v3_paths.user(0) }

    it_behaves_like "unprocessable", "recipient"
  end

  context "with a recipient that is a group" do
    let(:group) { create(:group, members: [recipient]) }
    let(:recipient_href) { api_v3_paths.user(group.id) }

    it_behaves_like "unprocessable", "recipient"
  end

  context "with a locked recipient" do
    before do
      recipient.locked!
    end

    it_behaves_like "unprocessable", "recipient"
  end

  context "with a recipient that is not allowed to view documents" do
    let(:recipient_href) { api_v3_paths.user(create(:user, member_with_permissions: { project => [] }).id) }

    it_behaves_like "unprocessable", "recipient"
  end

  context "when the document is not visible to the current user" do
    let(:current_user) { create(:user) }

    before { send_request }

    it_behaves_like "not found"
  end

  context "when the document does not exist" do
    let(:resource_href) { api_v3_paths.document(0) }

    before { send_request }

    it_behaves_like "not found"
  end

  context "when the current user may view but not edit the document" do
    let(:current_user) { recipient }
    let(:recipient_href) { api_v3_paths.user(caller_user.id) }

    before { send_request }

    it_behaves_like "unauthorized access"
  end

  context "as an anonymous user" do
    let(:current_user) { User.anonymous }

    before { send_request }

    it_behaves_like "forbidden response based on login_required"
  end
end
