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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "POST /api/v3/activities/:id/mark_read",
               content_type: :json,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:comment) do
    create(:work_package_journal, user: work_package.author, notes: "A comment", journable: work_package, version: 2)
  end

  let(:permissions) { %i[view_work_packages] }
  let(:activity) { comment }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  subject(:response) do
    post "#{api_v3_paths.activity(activity.id)}/mark_read"
    last_response
  end

  context "with an unread notification for the activity" do
    let!(:notification) do
      create(:notification, recipient: current_user, resource: work_package, journal: comment,
                            reason: :assigned, read_ian: false)
    end

    it "marks it read and keeps its reason" do
      expect(response).to have_http_status 204
      expect(notification.reload).to have_attributes(read_ian: true, reason: "assigned")
    end
  end

  context "without any notification for the activity" do
    it "responds with 204 without creating a notification" do
      expect(response).to have_http_status 204
      expect(Notification.count).to eq 0
    end
  end

  context "for an activity of a project" do
    let(:activity) { project.journals.last }

    it "is rejected" do
      expect(response).to have_http_status 403
    end
  end

  context "without permission to view the work package" do
    let(:permissions) { [] }
    let!(:notification) do
      create(:notification, recipient: current_user, resource: work_package, journal: comment,
                            reason: :assigned, read_ian: false)
    end

    it "responds with not found and leaves the notification unread" do
      expect(response).to have_http_status 404
      expect(notification.reload.read_ian).to be false
    end
  end
end
