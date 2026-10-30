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

RSpec.describe WorkPackageTypes::ProjectsTab::LinksController do
  let(:project) { create(:project) }
  let(:type) { create(:type_bug) }
  let(:user) { create(:admin) }

  before do
    login_as user
  end

  def node_payload(project)
    { path: [project.name], nodeId: project.id.to_s }.to_json
  end

  describe "GET new" do
    it "opens the add projects dialog" do
      get :new, params: { type_id: type.id }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(WorkPackageTypes::ProjectsTab::AddFormComponent::DIALOG_ID)
    end
  end

  describe "POST create" do
    it "puts the chosen projects on the variant" do
      post :create, params: { type_id: type.id, project_ids: [node_payload(project)] }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(project.reload.type_variant(type)).to eq(type.default_variant)
    end

    it "reaches the descendants too when asked to include sub-items" do
      child = create(:project, parent: project)

      post :create,
           params: { type_id: type.id, project_ids: [node_payload(project)], include_sub_items: "1" },
           format: :turbo_stream

      expect(child.reload.enabled_types).to include(type)
    end

    it "ignores a payload naming no project" do
      post :create, params: { type_id: type.id, project_ids: ["not json"] }, format: :turbo_stream

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an empty selection" do
      post :create, params: { type_id: type.id, project_ids: [] }, format: :turbo_stream

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include(I18n.t("types.edit.projects.add_dialog.no_projects_selected"))
    end

    context "when a project already applies another variant" do
      let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }
      let(:other_variant) { create(:type_variant, type:, variant_name: "Firmware") }

      before { create(:project_type, project:, type:, variant: other_variant) }

      it "switches it over rather than adding a second row" do
        post :create,
             params: { type_id: type.id, variant_id: variant.id, project_ids: [node_payload(project)],
                       confirm_switch: "1" },
             format: :turbo_stream

        expect(project.project_types.where(type_id: type.id).count).to eq(1)
        expect(project.reload.type_variant(type)).to eq(variant)
      end
    end
  end

  describe "DELETE destroy" do
    before { create(:project_type, project:, type:) }

    it "drops the type from the project" do
      delete :destroy, params: { type_id: type.id, project_ids: [project.id] }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(project.reload.enabled_types).not_to include(type)
    end

    context "when the project holds work packages of the type" do
      before { create(:work_package, project:, type:) }

      it "refuses and names the affected work packages" do
        delete :destroy, params: { type_id: type.id, project_ids: [project.id] }, format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(project.reload.enabled_types).to include(type)
      end

      it "links to the work packages standing in the way" do
        delete :destroy, params: { type_id: type.id, project_ids: [project.id] }, format: :turbo_stream

        expect(response.body)
          .to include(CGI.escapeHTML(work_packages_path(query_props: { f: [
            { n: "type", o: "=", v: [type.id] },
            { n: "project", o: "=", v: [project.id.to_s] }
          ] }.to_json)))
      end
    end
  end
end
