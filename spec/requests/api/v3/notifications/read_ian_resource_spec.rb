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
               "update read status",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:notification) do
    create(:notification,
           recipient:,
           resource: work_package)
  end

  let(:send_read) do
    post api_v3_paths.notification_read_ian(notification.id)
  end

  let(:send_unread) do
    post api_v3_paths.notification_unread_ian(notification.id)
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  before do
    login_as current_user
  end

  describe "recipient user" do
    let(:current_user) { recipient }

    it "can read and unread" do
      send_read
      expect(last_response).to have_http_status(:no_content)
      expect(notification.reload.read_ian).to be_truthy

      send_unread
      expect(last_response).to have_http_status(:no_content)
      expect(notification.reload.read_ian).to be_falsey
    end
  end

  describe "admin user" do
    let(:current_user) { build(:admin) }

    it "returns a 404 response" do
      send_read
      expect(last_response).to have_http_status(:not_found)

      send_unread
      expect(last_response).to have_http_status(:not_found)
    end
  end
end
