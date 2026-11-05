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

RSpec.describe Projects::Settings::TimeTrackingController, :skip_csrf, type: :rails_request do
  let(:project) { create(:project, enabled_module_names: %i[costs]) }
  let(:permissions) { %i[edit_project] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as(user) }

  describe "GET #show" do
    it "renders the settings" do
      get project_settings_time_tracking_path(project)

      expect(response).to have_http_status(:ok)
      expect(page).to have_field("project[logged_time_reduces_remaining_work]", disabled: false)
      expect(page).to have_no_css("[data-test-selector='time-tracking-status-based-banner']")
    end

    context "in status-based progress mode", with_settings: { work_package_done_ratio: "status" } do
      it "disables the settings and explains why" do
        get project_settings_time_tracking_path(project)

        expect(page).to have_css("[data-test-selector='time-tracking-status-based-banner']")
        expect(page).to have_field("project[logged_time_reduces_remaining_work]", disabled: true)
        expect(page).to have_field("project[remaining_work_read_only]", disabled: true)
        expect(page).to have_button(I18n.t(:button_save), disabled: true)
      end
    end
  end

  describe "PATCH #update" do
    it "updates both settings" do
      patch project_settings_time_tracking_path(project),
            params: { project: { logged_time_reduces_remaining_work: "1", remaining_work_read_only: "1" } }

      expect(response).to redirect_to(project_settings_time_tracking_path(project))
      expect(project.reload.logged_time_reduces_remaining_work).to be(true)
      expect(project.remaining_work_read_only).to be(true)
    end

    it "disables both settings" do
      project.update!(logged_time_reduces_remaining_work: true, remaining_work_read_only: true)

      patch project_settings_time_tracking_path(project),
            params: { project: { logged_time_reduces_remaining_work: "0", remaining_work_read_only: "0" } }

      expect(project.reload.logged_time_reduces_remaining_work).to be(false)
      expect(project.remaining_work_read_only).to be(false)
    end
  end

  context "when the user lacks :edit_project" do
    let(:permissions) { %i[manage_project_activities] }

    it "blocks show" do
      get project_settings_time_tracking_path(project)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks update" do
      patch project_settings_time_tracking_path(project),
            params: { project: { logged_time_reduces_remaining_work: "1" } }

      expect(response).to have_http_status(:forbidden)
      expect(project.reload.logged_time_reduces_remaining_work).to be_nil
    end
  end
end
