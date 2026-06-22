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

# A real session login (rather than the current_user stub) is required so the
# request runs through user_setup. Otherwise User.current is stubbed from the
# start and the project is never loaded as an anonymous user, which is exactly
# the regression these specs guard against on a private project.
RSpec.describe "Backlogs::Sprints", :skip_csrf, type: :rails_request do
  let(:password) { "adminADMIN!" }
  let(:user) do
    create(:user,
           password:,
           password_confirmation: password,
           member_with_permissions: { project => %i[view_sprints create_sprints view_work_packages show_board_views] })
  end

  before do
    post signin_path, params: { username: user.login, password: }
    follow_redirect! while response.redirect?
  end

  describe "PUT #update" do
    let(:project) do
      create(:project, public: true, enabled_module_names: %w[work_package_tracking backlogs])
    end
    let!(:sprint) { create(:sprint, name: "Original sprint name", project:) }

    it "loads the sprint from sprint_id and updates it", :aggregate_failures do
      put "/projects/#{project.identifier}/backlogs/sprints/#{sprint.id}",
          headers: { "ACCEPT" => "text/vnd.turbo-stream.html" },
          params: { sprint: { name: "Changed sprint name" } }

      expect(response).to be_successful
      expect(sprint.reload.name).to eq("Changed sprint name")
    end
  end

  describe "private project access" do
    let(:project) do
      create(:project, public: false, enabled_module_names: %w[work_package_tracking backlogs])
    end

    it "GET #index is reachable" do
      get project_backlogs_sprints_path(project)

      expect(response).to have_http_status(:ok)
    end

    it "GET #new_dialog is reachable" do
      get new_dialog_project_backlogs_sprints_path(project), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
    end

    it "POST #create is reachable", :aggregate_failures do
      post project_backlogs_sprints_path(project),
           headers: { "Accept" => "text/vnd.turbo-stream.html" },
           params: { sprint: { name: "New sprint", start_date: Time.zone.today, finish_date: Time.zone.today + 14.days } }

      expect(response).to be_successful
      expect(Sprint.for_project(project).where(name: "New sprint")).to exist
    end
  end
end
