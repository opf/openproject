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

RSpec.describe Projects::Settings::TimeAndCostsController, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[costs]) }

  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as(user) }

  context "when the user can edit the project" do
    let(:permissions) { %i[edit_project manage_project_activities] }

    it "redirects to the time tracking settings" do
      get project_settings_time_and_costs_path(project)

      expect(response).to redirect_to(project_settings_time_tracking_path(project))
    end
  end

  context "when the user can only manage activities" do
    let(:permissions) { %i[manage_project_activities] }

    it "redirects to the activities" do
      get project_settings_time_and_costs_path(project)

      expect(response).to redirect_to(project_settings_time_entry_activities_path(project))
    end
  end

  context "when the user has neither permission" do
    let(:permissions) { %i[view_work_packages] }

    it "is forbidden" do
      get project_settings_time_and_costs_path(project)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
