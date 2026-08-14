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

RSpec.describe WorkPackageTypes::ProjectsTabController do
  let(:project) { create(:project) }
  let(:type) { create(:type_bug) }

  before do
    login_as user
  end

  context "without admin access" do
    let(:user) { create :user }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  context "with admin access" do
    let(:user) { create :admin }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template "edit" }
    end

    describe "PUT update" do
      let(:project_ids) { [project.id.to_s] }
      let(:params) do
        {
          "type_id" => type.id,
          "type" => { "project_ids" => project_ids.to_json }
        }
      end

      def update_projects
        put :update, params:
      end

      it "redirects to the projects tab" do
        update_projects

        expect(response).to redirect_to(edit_type_projects_path(type_id: type.id))
      end

      context "if the project id does not exist" do
        let(:project_ids) { ["not_here"] }

        it "responds with an error" do
          update_projects

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "if the project contains work packages of the type" do
        let(:project) { create(:project, types: [type]) }
        let!(:work_package) { create(:work_package, project:, type:) }
        let(:project_ids) { [] }

        before do
          update_projects
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }

        it "shows an error message with a link to the affected work packages" do
          expect(sanitize_string(flash[:error]))
            .to include("Unable to deactivate type #{type.name} because it's still in use by work packages")
          expect(flash[:error])
            .to include(work_packages_path(query_props: { f: [
              { n: "type", o: "=", v: [type.id] },
              { n: "project", o: "=", v: [project.id.to_s] }
            ] }.to_json))
        end

        it "keeps the type active in the project" do
          expect(project.reload.types).to include(type)
        end
      end

      context "if visible and invisible projects contain work packages of the type" do
        let(:project) { create(:project, types: [type]) }
        let(:archived_project) { create(:project, :archived, types: [type]) }
        let!(:work_package) { create(:work_package, project:, type:) }
        let!(:archived_work_package) { create(:work_package, project: archived_project, type:) }
        let(:project_ids) { [] }

        before do
          update_projects
        end

        it "does not include invisible project ids in the work packages link" do
          expect(flash[:error])
            .to include(work_packages_path(query_props: { f: [
              { n: "type", o: "=", v: [type.id] },
              { n: "project", o: "=", v: [project.id.to_s] }
            ] }.to_json))
        end

        it "informs the user that some projects are not visible" do
          expect(flash[:error])
            .to include(I18n.t(:error_can_not_deactivate_type_invisible_projects))
        end
      end
    end

    describe "POST enable_all_projects" do
      let!(:project) { create(:project) }
      let!(:other_project) { create(:project) }

      def enable_all_projects(value)
        post :enable_all_projects, params: { type_id: type.id, value: }, format: :turbo_stream
      end

      context "when enabling" do
        before do
          enable_all_projects("1")
        end

        it { expect(response).to have_http_status(:ok) }

        it "activates the type in all projects" do
          expect(type.reload.projects).to contain_exactly(project, other_project)
        end
      end

      context "when disabling" do
        let(:type) { create(:type_bug, projects: [project, other_project]) }

        before do
          enable_all_projects("0")
        end

        it { expect(response).to have_http_status(:ok) }

        it "deactivates the type in all projects" do
          expect(type.reload.projects).to be_empty
        end
      end

      context "when disabling is blocked by existing work packages" do
        let(:type) { create(:type_bug, projects: [project, other_project]) }
        let!(:work_package) { create(:work_package, project:, type:) }

        before do
          enable_all_projects("0")
        end

        it { expect(response).to have_http_status(:ok) }

        it "keeps the type active in all projects" do
          expect(type.reload.projects).to contain_exactly(project, other_project)
        end

        it "renders an error message naming the affected work packages" do
          expect(sanitize_string(response.body))
            .to include("Unable to deactivate type #{type.name} because it's still in use by work packages")
        end

        it "re-renders the projects component with the toggle switch still turned on" do
          expect(response.body).to include('target="work-package-types-projects-component"')
          expect(response.body).to include("ToggleSwitch--checked")
        end
      end
    end
  end
end
