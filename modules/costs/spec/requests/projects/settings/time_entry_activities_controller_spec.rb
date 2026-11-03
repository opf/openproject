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

require_relative "../../../spec_helper"

RSpec.describe Projects::Settings::TimeEntryActivitiesController, :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[costs]) }

  let(:permissions) { %i[manage_project_activities] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let!(:activity) { create(:time_entry_activity, active: true) }

  before { login_as(user) }

  describe "GET #show" do
    it "renders the list of activities" do
      get project_settings_time_entry_activities_path(project)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #toggle" do
    context "when no mapping exists yet (active by default via the global activity)" do
      it "creates a mapping that disables the activity in the project" do
        expect do
          post toggle_project_settings_time_entry_activities_path(project, activity)
        end.to change { TimeEntryActivitiesProject.where(project:, activity:).count }.from(0).to(1)
        expect(TimeEntryActivitiesProject.find_by(project:, activity:).active).to be(false)
        expect(response).to redirect_to(project_settings_time_entry_activities_path(project))
      end
    end

    context "when the mapping already disables the activity" do
      before { TimeEntryActivitiesProject.create!(project:, activity:, active: false) }

      it "re-enables the mapping" do
        expect do
          post toggle_project_settings_time_entry_activities_path(project, activity)
        end.to change { TimeEntryActivitiesProject.find_by(project:, activity:).active }.from(false).to(true)
      end
    end
  end

  context "when user lacks :manage_project_activities" do
    let(:permissions) { %i[view_work_packages] }

    it "blocks show" do
      get project_settings_time_entry_activities_path(project)
      expect(response).to have_http_status(:forbidden)
    end

    it "blocks toggle" do
      expect do
        post toggle_project_settings_time_entry_activities_path(project, activity)
      end.not_to change(TimeEntryActivitiesProject, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
