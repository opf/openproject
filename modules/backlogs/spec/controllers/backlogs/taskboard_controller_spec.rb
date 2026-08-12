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

RSpec.describe Backlogs::TaskboardController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  let(:user) { create(:user) }
  let(:permissions) { [] }
  let(:project) { create(:project, member_with_permissions: { user => permissions }) }
  let(:status) { create(:status, name: "status 1", is_default: true) }
  let(:board) { create(:board_grid_with_query, project:) }

  current_user { user }

  describe "GET show" do
    let(:sprint) { create(:sprint, project:) }

    context "when the board exists" do
      let!(:other_project) { create(:project) }
      let!(:other_board) { create(:board_grid_with_query, project: other_project, linked: sprint) }

      before do
        board.update!(linked: sprint)
      end

      context "as a member with view_sprints permission" do
        let(:permissions) { %i[view_sprints view_work_packages] }

        before do
          get :show, params: { project_id: project.identifier, sprint_id: sprint.id }
        end

        it "redirects to the board" do
          expect(response).to redirect_to(project_work_package_board_path(project, board))
        end

        it "uses the board for the current project" do
          expect(response).to redirect_to(project_work_package_board_path(project, board))
          expect(response).not_to redirect_to(project_work_package_board_path(other_project, other_board))
          expect(controller.controller_path).to eq("backlogs/taskboard")
        end
      end
    end

    context "when the board does not exist" do
      let(:permissions) { %i[view_sprints view_work_packages] }

      before do
        get :show, params: { project_id: project.identifier, sprint_id: sprint.id }
      end

      it "returns not found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the sprint is rendered in a receiving project" do
      let(:source_project) { create(:project, sprint_sharing: "share_all_projects") }
      let(:project) do
        create(:project,
               sprint_sharing: "receive_shared",
               member_with_permissions: { user => permissions })
      end
      let(:permissions) { %i[view_sprints view_work_packages] }
      let(:sprint) { create(:sprint, project: source_project) }

      before do
        create(:board_grid_with_query, project: source_project, linked: sprint)
        get :show, params: { project_id: project.identifier, sprint_id: sprint.id }
      end

      it "returns not found when the receiving project has no task board" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a member without view_sprints permission" do
      let(:permissions) { [:view_project] }

      before do
        board.update!(linked: sprint)
        get :show, params: { project_id: project.identifier, sprint_id: sprint.id }
      end

      it "denies access" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a non-member" do
      current_user { create(:user) }

      before do
        board.update!(linked: sprint)
        get :show, params: { project_id: project.identifier, sprint_id: sprint.id }
      end

      it "denies access" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
