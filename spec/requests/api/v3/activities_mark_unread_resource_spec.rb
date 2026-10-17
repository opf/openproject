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

RSpec.describe "POST /api/v3/activities/:id/mark_unread",
               content_type: :json,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:comment) do
    create(:work_package_journal, user: work_package.author, notes: "A comment", journable: work_package, version: 2)
  end
  shared_let(:later_comment) do
    create(:work_package_journal, user: work_package.author, notes: "Later", journable: work_package, version: 3)
  end

  let(:permissions) { %i[view_work_packages] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  subject(:response) do
    post "#{api_v3_paths.activity(comment.id)}/mark_unread"
    last_response
  end

  it "marks the given activity as unread" do
    expect(response.status).to eq 204
    expect(Notification.where(recipient: current_user, read_ian: false).sole)
      .to have_attributes(journal: comment, resource: work_package, reason: "marked_as_unread")
  end

  context "with a read notification for the activity" do
    let!(:notification) do
      create(:notification, recipient: current_user, resource: work_package, journal: comment,
                            reason: :assigned, read_ian: true)
    end

    it "marks it unread and keeps its reason" do
      expect(response.status).to eq 204
      expect(notification.reload).to have_attributes(read_ian: false, reason: "assigned")
    end
  end

  context "without permission to view the work package" do
    let(:permissions) { [] }

    it "responds with not found" do
      expect(response.status).to eq 404
      expect(Notification.count).to eq 0
    end
  end
end
