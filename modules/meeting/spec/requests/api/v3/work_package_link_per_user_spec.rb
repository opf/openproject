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

RSpec.describe "API v3 meeting work package link rendering", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:meeting_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:work_package_project) { create(:project, enabled_module_names: %w[work_package_tracking]) }

  shared_let(:user_with_access) do
    create(:user,
           member_with_permissions: {
             meeting_project => %i[view_meetings],
             work_package_project => %i[view_work_packages]
           })
  end
  shared_let(:user_without_access) do
    create(:user, member_with_permissions: { meeting_project => %i[view_meetings] })
  end

  shared_let(:work_package) { create(:work_package, project: work_package_project, subject: "Linked subject") }
  shared_let(:meeting) { create(:meeting, project: meeting_project, author: user_with_access) }
  shared_let(:section) { create(:meeting_section, meeting:) }
  shared_let(:agenda_item) do
    create(:wp_meeting_agenda_item, meeting:, meeting_section: section, work_package:, author: user_with_access)
  end
  shared_let(:outcome) do
    create(:meeting_outcome, meeting_agenda_item: agenda_item, author: user_with_access, kind: :work_package, work_package:)
  end

  def link_for(user, path)
    login_as user
    get path
    expect(last_response).to have_http_status(:ok)

    JSON.parse(last_response.body).dig("_links", "workPackage")
  end

  shared_examples "renders the link for each requesting user" do
    it "discloses the work package only to the user with access, whoever asks first" do
      first = link_for(first_user, path)
      second = link_for(second_user, path)

      by_user = { first_user => first, second_user => second }

      expect(by_user[user_with_access]["href"]).to eq api_v3_paths.work_package(work_package.id)
      expect(by_user[user_with_access]["title"]).to eq work_package.subject

      expect(by_user[user_without_access]["href"]).to eq API::V3::URN_UNDISCLOSED
      expect(by_user[user_without_access]["title"]).not_to eq work_package.subject
    end
  end

  describe "GET /api/v3/meeting_agenda_items/:id" do
    let(:path) { api_v3_paths.meeting_agenda_item(agenda_item.id) }

    context "when the user with access asks first" do
      let(:first_user) { user_with_access }
      let(:second_user) { user_without_access }

      it_behaves_like "renders the link for each requesting user"
    end

    context "when the user without access asks first" do
      let(:first_user) { user_without_access }
      let(:second_user) { user_with_access }

      it_behaves_like "renders the link for each requesting user"
    end
  end

  describe "GET /api/v3/meeting_outcomes/:id" do
    let(:path) { api_v3_paths.meeting_outcome(outcome.id) }

    context "when the user with access asks first" do
      let(:first_user) { user_with_access }
      let(:second_user) { user_without_access }

      it_behaves_like "renders the link for each requesting user"
    end

    context "when the user without access asks first" do
      let(:first_user) { user_without_access }
      let(:second_user) { user_with_access }

      it_behaves_like "renders the link for each requesting user"
    end
  end
end
