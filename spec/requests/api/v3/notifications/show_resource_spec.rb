#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require_relative "show_resource_examples"

RSpec.describe API::V3::Notifications::NotificationsAPI,
               "show",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:recipient) do
    create(:user)
  end
  shared_let(:role) { create(:project_role, permissions: %i(view_work_packages)) }
  shared_let(:project) do
    create(:project,
           members: { recipient => role })
  end
  shared_let(:resource) { create(:work_package, project:) }
  shared_let(:notification) do
    create(:notification,
           recipient:,
           resource:,
           journal: resource.journals.last)
  end

  let(:send_request) do
    get api_v3_paths.notification(notification.id)
  end

  describe "recipient user" do
    current_user { recipient }

    before do
      send_request
    end

    it_behaves_like "represents the notification"
  end

  describe "recipient user for a dateAlert notification" do
    current_user { recipient }

    before do
      notification.reason = :date_alert_due_date
      notification.journal = nil
      notification.actor = nil
      notification.save!

      resource.update_column(:due_date, Date.current)

      send_request
    end

    it_behaves_like "represents the notification"

    it "includes the value of the work package associated in the details", :aggregate_failures do
      expect(last_response.body)
        .to be_json_eql("dueDate".to_json)
              .at_path("_embedded/details/0/property")

      expect(last_response.body)
        .to be_json_eql(API::V3::Utilities::DateTimeFormatter.format_date(resource.due_date).to_json)
              .at_path("_embedded/details/0/value")
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
