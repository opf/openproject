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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../../spec_helper"

RSpec.describe Projects::Settings::CostTypesController, :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[costs]) }

  let(:permissions) { %i[manage_project_activities] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let!(:global_ct) { create(:cost_type, for_all_projects: true) }
  let!(:scoped_ct) { create(:cost_type, for_all_projects: false) }

  before { login_as(user) }

  describe "GET #index" do
    it "renders the list of cost types" do
      get project_settings_cost_types_path(project)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #toggle" do
    context "with a non-global cost type not yet enabled in the project" do
      it "creates the mapping" do
        expect do
          post toggle_project_settings_cost_type_path(project, scoped_ct)
        end.to change { CostTypesProject.where(project:, cost_type: scoped_ct).count }.from(0).to(1)
        expect(response).to redirect_to(project_settings_cost_types_path(project))
      end
    end

    context "with a non-global cost type already enabled" do
      before { CostTypesProject.create!(project:, cost_type: scoped_ct) }

      it "removes the mapping" do
        expect do
          post toggle_project_settings_cost_type_path(project, scoped_ct)
        end.to change { CostTypesProject.where(project:, cost_type: scoped_ct).count }.from(1).to(0)
      end
    end

    context "with a global cost type" do
      it "rejects toggling" do
        expect do
          post toggle_project_settings_cost_type_path(project, global_ct)
        end.not_to change(CostTypesProject, :count)
        expect(flash[:error]).to be_present
      end
    end
  end

  context "when user lacks :manage_project_activities" do
    let(:permissions) { %i[view_work_packages] }

    it "blocks index" do
      get project_settings_cost_types_path(project)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
