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

require "spec_helper"

RSpec.describe WorkPackageTypes::TypesController do
  let(:project) do
    create(:project,
           work_package_custom_fields: [custom_field_2])
  end
  let(:custom_field_1) do
    create(:work_package_custom_field,
           field_format: "string",
           is_for_all: true)
  end
  let(:custom_field_2) { create(:work_package_custom_field) }
  let(:status_old) { create(:status) }
  let(:status_new) { create(:status) }

  context "with an unauthorized account" do
    let(:current_user) { create(:user) }

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe "GET index" do
      describe "the access should be restricted" do
        before { get "index" }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    describe "GET new" do
      describe "the access should be restricted" do
        before { get "new" }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    describe "POST create" do
      describe "the access should be restricted" do
        before { post "create" }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    describe "DELETE destroy" do
      describe "the access should be restricted" do
        before { delete "destroy", params: { id: "123" } }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    describe "POST move" do
      describe "the access should be restricted" do
        before { post "move", params: { id: "123" } }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end
  end

  context "with an authorized account" do
    let(:current_user) { create(:admin) }

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    describe "GET index" do
      before { get "index" }

      it { expect(response).to be_successful }
      it { expect(response).to render_template "index" }
    end

    describe "GET new" do
      before { get "new" }

      it { expect(response).to be_successful }
      it { expect(response).to render_template "new" }
    end

    describe "POST create" do
      describe "WITH valid params" do
        let(:params) do
          { "type" => { name: "New type",
                        project_ids: { "1" => project.id },
                        custom_field_ids: { "1" => custom_field_1.id,
                                            "2" => custom_field_2.id } } }
        end

        before do
          post :create, params:
        end

        it { expect(response).to be_redirect }

        it do
          type = Type.find_by(name: "New type")
          expect(response).to redirect_to(edit_type_details_path(type_id: type.id))
        end
      end

      describe "WITH an empty name" do
        render_views
        let(:params) do
          { "type" => { name: "",
                        project_ids: { "1" => project.id },
                        custom_field_ids: { "1" => custom_field_1.id,
                                            "2" => custom_field_2.id } } }
        end

        before do
          post :create, params:
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }

        it "shows an error message on the name field" do
          expect(response.body).to have_text("can't be blank")
        end
      end

      describe "WITH workflow copy" do
        let!(:existing_type) { create(:type, name: "Existing type") }
        let!(:workflow) do
          create(:workflow,
                 old_status: status_old,
                 new_status: status_new,
                 type_id: existing_type.id)
        end

        let(:params) do
          {
            "type" => {
              name: "New type",
              project_ids: { "1" => project.id },
              custom_field_ids: { "1" => custom_field_1.id, "2" => custom_field_2.id },
              copy_workflow_from: existing_type.id
            }
          }
        end

        before do
          post :create, params:
        end

        it { expect(response).to be_redirect }

        it do
          type = Type.find_by(name: "New type")
          expect(response).to redirect_to(edit_type_details_path(type_id: type.id))
        end

        it "has the copied workflows" do
          expect(Type.find_by(name: "New type")
                        .default_variant.workflows.count).to eq(existing_type.default_variant.workflows.count)
        end
      end
    end

    describe "POST move" do
      context "with a successful update" do
        let!(:type) { create(:type, name: "My type", position: "1") }
        let!(:type2) { create(:type, name: "My type 2", position: "2") }
        let(:params) { { "id" => type.id, "type" => { move_to: "lower" } } }

        before do
          post :move, params:
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }

        it "has the position updated" do
          expect(Type.find_by(name: "My type").position).to eq(2)
        end
      end

      context "with a failed update" do
        let!(:type) { create(:type, name: "My type", position: "1") }
        let!(:type2) { create(:type, name: "My type 2", position: "2") }
        let(:params) { { "id" => type.id, "type" => { move_to: "lower" } } }

        before do
          allow(Type).to receive(:find).and_return(type)
          allow(type).to receive(:update).and_return false

          post :move, params:
        end

        it { expect(response).to redirect_to(types_path) }

        it "has an unsuccessful move flash" do
          expect(flash[:error]).to eq(I18n.t(:error_type_could_not_be_saved))
        end

        it "doesn't update the position" do
          expect(Type.find_by(name: "My type").position).to eq(1)
        end
      end
    end

    describe "DELETE destroy" do
      let(:type) { create(:type, name: "My type") }
      let(:type2) { create(:type, name: "My type 2", projects: [project]) }
      let(:type3) { create(:type, name: "My type 3") }

      describe "successful destroy" do
        let(:params) { { "id" => type.id } }

        before do
          delete :destroy, params:
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }

        it "has a successful destroy flash" do
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
        end

        it "is not present in the database" do
          expect(Type.find_by(name: "My type")).to be_nil
        end
      end

      describe "destroy type in use should fail" do
        let(:archived_project) do
          create(:project,
                 :archived,
                 work_package_custom_fields: [custom_field_2],
                 types: [type2])
        end
        let!(:work_package) do
          create(:work_package,
                 author: current_user,
                 type: type2,
                 project: archived_project)
        end
        let(:params) { { "id" => type2.id } }

        let(:error_message) do
          archived_projects_urls = described_class
                                     .helpers
                                     .archived_projects_urls_for([archived_project])
          [
            I18n.t(:"error_can_not_delete_type.explanation"),
            I18n.t(:error_can_not_delete_in_use_archived_work_packages, archived_projects_urls:)
          ]
        end

        before do
          delete :destroy, params:
        end

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }

        it "shows an error message" do
          expect(sanitize_string(flash[:error])).to eq(sanitize_string(error_message))
        end

        it "is present in the database" do
          expect(Type.find_by(name: "My type 2").id).to eq(type2.id)
        end
      end

      describe "destroy standard type should fail" do
        let(:params) { { "id" => type3.id } }

        before { delete :destroy, params: }

        it { expect(response).to be_redirect }
        it { expect(response).to redirect_to(types_path) }
      end
    end

    describe "GET index with variants", with_flag: { type_variants: true } do
      let!(:bug) { create(:type, name: "Bug") }
      let!(:named_variant) { create(:type_variant, type: bug, variant_name: "Hardware") }
      let!(:other_type) { create(:type, name: "Other") }

      before { get :index }

      it "assigns types to @types" do
        expect(assigns(:types)).to include(bug, other_type)
      end

      it "exposes each type's named variants" do
        assigned_bug = assigns(:types).detect { |type| type == bug }
        expect(assigned_bug.variants.non_default_variants).to contain_exactly(named_variant)
      end
    end

    describe "PUT drop", with_flag: { type_variants: true } do
      let!(:first_type) { create(:type, name: "First") }
      let!(:second_type) { create(:type, name: "Second") }

      it "reorders the dropped type to the given position" do
        expect(first_type.position).to be < second_type.position

        put :drop, params: { id: second_type.id, position: 1 }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(second_type.reload.position).to eq(1)
        expect(second_type.position).to be < first_type.reload.position
      end

      context "when the variants feature is disabled", with_flag: { type_variants: false } do
        it "is not available" do
          put :drop, params: { id: second_type.id, position: 1 }, format: :turbo_stream

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "GET index without the variants feature", with_flag: { type_variants: false } do
      let!(:bug) { create(:type, name: "Bug") }
      let!(:other_type) { create(:type, name: "Other") }

      before { get :index }

      it "lists types" do
        expect(assigns(:types)).to include(bug, other_type)
      end
    end
  end
end
