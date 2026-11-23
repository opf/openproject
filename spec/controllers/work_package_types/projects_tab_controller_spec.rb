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

    describe "POST enable_all" do
      before { project }

      it "puts every project on the base variant" do
        post :enable_all_projects, params: { type_id: type.id, value: "1" }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(project.reload.type_variant(type)).to eq(type.default_variant)
      end

      it "drops the type everywhere when toggled off" do
        create(:project_type, project:, type:)

        post :enable_all_projects, params: { type_id: type.id, value: "0" }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(project.enabled_types).not_to include(type)
      end

      context "when work packages stand in the way of one project" do
        let!(:other_project) { create(:project) }

        before do
          create(:project_type, project:, type:)
          create(:project_type, project: other_project, type:)
          create(:work_package, project:, type:)

          post :enable_all_projects, params: { type_id: type.id, value: "0" }, format: :turbo_stream
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }

        it "drops the type from the projects it can and leaves the blocked one alone" do
          expect(type.reload.projects).to contain_exactly(project)
        end

        it "names the blocked project" do
          expect(sanitize_string(response.body))
            .to include("Unable to remove \"#{type.name}\" from project \"#{project.name}\" " \
                        "because it's still in use by work packages")
        end

        it "links to the work packages standing in the way" do
          expect(response.body)
            .to include(CGI.escapeHTML(work_packages_path(query_props: { f: [
              { n: "type", o: "=", v: [type.id] },
              { n: "project", o: "=", v: [project.id.to_s] }
            ] }.to_json)))
        end

        it "reloads the projects listing" do
          expect(response.body).to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
        end
      end

      context "when work packages stand in the way in a project the admin cannot see" do
        let(:archived_project) { create(:project, :archived) }

        before do
          create(:project_type, project:, type:)
          create(:project_type, project: archived_project, type:)
          create(:work_package, project:, type:)
          create(:work_package, project: archived_project, type:)

          post :enable_all_projects, params: { type_id: type.id, value: "0" }, format: :turbo_stream
        end

        it "says some projects are hidden" do
          expect(sanitize_string(response.body)).to include("There are also work packages in projects you cannot see.")
        end

        it "links only to the work packages of the project the admin can see" do
          link_to = ->(blocked) do
            CGI.escapeHTML(work_packages_path(query_props: { f: [
              { n: "type", o: "=", v: [type.id] },
              { n: "project", o: "=", v: [blocked.id.to_s] }
            ] }.to_json))
          end

          expect(response.body).to include(link_to[project])
          expect(response.body).not_to include(link_to[archived_project])
        end
      end

      context "when another variant's project holds work packages of the type" do
        let(:other_variant) { create(:type_variant, type:, variant_name: "Firmware") }

        before do
          create(:project_type, project:, type:, variant: other_variant)
          create(:work_package, project:, type:)

          post :enable_all_projects, params: { type_id: type.id, value: "0" }, format: :turbo_stream
        end

        it "leaves it on its variant" do
          expect(response).to have_http_status(:ok)
          expect(project.reload.type_variant(type)).to eq(other_variant)
        end
      end
    end
  end
end
