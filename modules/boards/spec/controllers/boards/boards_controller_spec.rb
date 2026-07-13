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

RSpec.describe Boards::BoardsController do
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:permissions) { %i[view_work_packagess show_board_views] }
  let(:board) { create(:board_grid, project: project) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "#destroy" do
    context "when allowed to delete boards" do
      let(:permissions) { %i[view_work_packagess show_board_views manage_board_views] }

      it "returns 200 ok" do
        delete :destroy, params: { id: board.id, project_id: project.id }

        expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
        expect(response).to redirect_to(project_work_package_boards_path(project))
        expect(response).to have_http_status(:see_other)
      end
    end

    context "when not allowed to delete boards" do
      let(:permissions) { %i[view_work_packagess show_board_views] }

      it "returns 403 forbidden" do
        delete :destroy, params: { id: board.id, project_id: project.id }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not allowed to delete boards in this project, but in others (Regression #69942)" do
      let(:other_project) { create(:project) }
      let(:user) do
        create(:user, member_with_permissions: {
                 project => %i[view_work_packagess show_board_views],
                 other_project => %i[view_work_packages manage_board_views]
               })
      end

      it "returns 403 forbidden" do
        delete :destroy, params: { id: board.id, project_id: project.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
