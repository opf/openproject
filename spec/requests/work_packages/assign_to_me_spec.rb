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

require "rails_helper"

RSpec.describe "POST work package assign to me", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }

  let(:permissions) { %i[view_work_packages edit_work_packages work_package_assigned] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:, subject: "Plan the conference") }

  current_user { user }

  subject(:request) do
    post "/work_packages/#{work_package.id}/assign_to_me", as: :turbo_stream
  end

  it "assigns the work package to the user and tells them so" do
    request

    expect(work_package.reload.assigned_to).to eq(user)
    expect(response).to have_turbo_stream(action: "flash")
    expect(response.body).to include("#{work_package.formatted_id} Plan the conference is now assigned to you.")
  end

  it "lets other views on the work package know it changed" do
    request

    expect(response).to have_turbo_stream(action: "dispatchEvent")
    expect(response.body).to include(%(event-name="#{WorkPackagesController::UPDATED_EVENT_NAME}"))
  end

  context "when the user may not edit the work package" do
    let(:permissions) { %i[view_work_packages work_package_assigned] }

    it "leaves the assignee alone and tells the user why" do
      request

      expect(work_package.reload.assigned_to).to be_nil
      expect(response).to have_turbo_stream(action: "flash")
      expect(response.body).to include("Banner--error")
      expect(response).not_to have_turbo_stream(action: "dispatchEvent")
    end
  end

  context "when the user cannot see the work package" do
    let(:user) { create(:user) }

    it "responds as if it did not exist and tells the user so" do
      request

      expect(response).to have_http_status(:not_found)
      expect(response).to have_turbo_stream(action: "flash")
      expect(response.body).to include("Banner--error")
      expect(work_package.reload.assigned_to).to be_nil
    end
  end

  context "when assigning fails unexpectedly" do
    before do
      allow(WorkPackages::UpdateService).to receive(:new).and_raise(StandardError, "boom")
    end

    it "tells the user something went wrong" do
      request

      expect(response).to have_http_status(:internal_server_error)
      expect(response).to have_turbo_stream(action: "flash")
      expect(response.body).to include("Banner--error")
      expect(response).not_to have_turbo_stream(action: "dispatchEvent")
    end
  end
end
