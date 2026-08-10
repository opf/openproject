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

        # The ids come from the project tree the form rendered, so an id naming no project is a
        # malformed request rather than something to report on. It selects no project to act on.
        it "ignores it" do
          update_projects

          expect(response).to redirect_to(edit_type_projects_path(type_id: type.id))
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

      # A ticked project is one applying the variant the tab addresses, so where the project
      # stands on the type decides which service runs for it.
      context "on a named variant's tab", with_flag: { type_variants: true } do
        let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }
        let(:params) do
          {
            "type_id" => type.id,
            "variant_id" => variant.id,
            "type" => { "project_ids" => project_ids.to_json }
          }
        end

        it "redirects to the variant's own projects tab" do
          update_projects

          expect(response).to redirect_to(edit_type_projects_path(type_id: type.id, variant_id: variant.id))
        end

        it "puts a project that does not use the type on this variant" do
          update_projects

          expect(project.reload.type_variant(type)).to eq(variant)
        end

        context "when the project applies another variant of the type" do
          let(:other_variant) { create(:type_variant, type:, variant_name: "Firmware") }

          before { create(:project_type, project:, type:, variant: other_variant) }

          it "switches it over rather than adding a second row" do
            update_projects

            expect(project.project_types.where(type_id: type.id).count).to eq(1)
            expect(project.reload.type_variant(type)).to eq(variant)
          end
        end

        context "when a project applying this variant is unticked" do
          let(:project_ids) { [] }

          before { create(:project_type, project:, type:, variant:) }

          it "drops the type from the project" do
            update_projects

            expect(project.reload.types).not_to include(type)
          end
        end

        context "when another variant's project holds work packages of the type" do
          let(:other_variant) { create(:type_variant, type:, variant_name: "Firmware") }
          let(:sibling_project) { create(:project) }

          before do
            create(:project_type, project: sibling_project, type:, variant: other_variant)
            create(:work_package, project: sibling_project, type:)
          end

          it "leaves it alone" do
            update_projects

            expect(response).to redirect_to(edit_type_projects_path(type_id: type.id, variant_id: variant.id))
            expect(sibling_project.reload.type_variant(type)).to eq(other_variant)
          end
        end
      end
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
        expect(project.reload.types).not_to include(type)
      end
    end
  end
end
