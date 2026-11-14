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

RSpec.describe "Projects::Settings::Versions",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[manage_versions] }) }

  before { login_as user }

  describe "GET #show" do
    let!(:open_version_recent) do
      create(:version, project:, status: "open", effective_date: 1.day.from_now)
    end
    let!(:open_version_old) do
      create(:version, project:, status: "open", effective_date: 30.days.from_now)
    end
    let!(:open_version_no_date) do
      create(:version, project:, status: "open", effective_date: nil)
    end
    let!(:locked_version) do
      create(:version, project:, status: "locked", effective_date: 5.days.from_now)
    end
    let!(:closed_version) do
      create(:version, project:, status: "closed", effective_date: 10.days.ago)
    end

    it "returns a successful response" do
      get project_settings_versions_path(project)

      expect(response).to have_http_status(:ok)
    end

    context "without any filters" do
      it "shows only open versions by default" do
        get project_settings_versions_path(project)

        expect(response.body).to include(open_version_recent.name)
        expect(response.body).to include(open_version_old.name)
        expect(response.body).to include(open_version_no_date.name)
        expect(response.body).not_to include(locked_version.name)
        expect(response.body).not_to include(closed_version.name)
      end
    end

    context "with status filter for all statuses" do
      it "shows versions of all statuses" do
        get project_settings_versions_path(project),
            params: { status: "=" }

        expect(response.body).to include(open_version_recent.name)
        expect(response.body).to include(locked_version.name)
        expect(response.body).to include(closed_version.name)
      end
    end

    context "when ordering versions" do
      it "orders by status first (open, locked, closed) then by effective_date DESC" do
        get project_settings_versions_path(project),
            params: { status: "=" }

        body = response.body
        open_recent_pos = body.index(open_version_recent.name)
        open_old_pos = body.index(open_version_old.name)
        open_no_date_pos = body.index(open_version_no_date.name)
        locked_pos = body.index(locked_version.name)
        closed_pos = body.index(closed_version.name)

        expect(open_old_pos).to be < open_recent_pos
        expect(open_recent_pos).to be < open_no_date_pos
        expect(open_no_date_pos).to be < locked_pos
        expect(locked_pos).to be < closed_pos
      end
    end

    context "when requesting as turbo frame" do
      it "renders without layout" do
        get project_settings_versions_path(project),
            headers: { "Turbo-Frame" => "versions-table" }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("<html")
      end
    end

    context "without manage_versions permission" do
      let(:user_without_permission) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      before { login_as user_without_permission }

      it "returns forbidden" do
        get project_settings_versions_path(project)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
