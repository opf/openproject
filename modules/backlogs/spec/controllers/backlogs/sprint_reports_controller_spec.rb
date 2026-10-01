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

RSpec.describe Backlogs::SprintReportsController do
  let(:all_permissions) { %i[view_sprints view_work_packages show_board_views] }
  let(:permissions) { all_permissions }
  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  describe "GET #show" do
    it "responds with success", :aggregate_failures do
      get :show, params: { project_id: project.id, sprint_id: sprint.id }

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(response).to render_template("backlogs/sprint_reports/show")
      expect(controller.controller_path).to eq("backlogs/sprint_reports")
      expect(assigns(:project)).to eq(project)
      expect(assigns(:sprint)).to eq(sprint)
    end

    context "without the 'view_sprints' permission" do
      let(:permissions) { %i[view_work_packages show_board_views] }

      it "responds with not_found" do
        get :show, params: { project_id: project.id, sprint_id: sprint.id }

        expect(response).to have_http_status :not_found
      end
    end
  end
end
