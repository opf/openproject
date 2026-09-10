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

RSpec.describe WorkPackageTypes::VariantsController do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }

  before { login_as user }

  context "with admin access" do
    let(:user) { admin }

    describe "GET index" do
      let!(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

      before { get :index, params: { type_id: type.id } }

      render_views

      it "renders the tab, listing the type's named variants" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).to include("Hardware")
      end
    end

    describe "GET index as a turbo frame request" do
      let!(:variant) { create(:type_variant, type:, variant_name: "Hardware") }
      let!(:other_variant) { create(:type_variant, type:, variant_name: "Software") }

      render_views

      before do
        request.headers["Turbo-Frame"] = WorkPackageTypes::VariantsListComponent::FRAME_ID

        get :index, params: { type_id: type.id, query: "hard" }
      end

      it "renders the filtered list on its own, without the surrounding page" do
        expect(response).to have_http_status(:ok)
        expect(response).not_to render_template(:index)
        expect(response.body).to include("Hardware")
        expect(response.body).not_to include("Software")
      end
    end

    describe "POST make_default" do
      context "for the base variant" do
        let(:variant) { type.default_variant }

        before { post :make_default, params: { type_id: type.id, id: variant.id } }

        it "marks it as the one new projects start with" do
          expect(response).to redirect_to(types_path)
          expect(variant.reload).to be_enabled_in_new_projects
        end
      end

      context "for a named variant" do
        let!(:variant) { create(:type_variant, type:) }

        before { post :make_default, params: { type_id: type.id, id: variant.id } }

        it "marks it too: either variant of a type can be the one new projects start with" do
          expect(response).to redirect_to(types_path)
          expect(variant.reload).to be_enabled_in_new_projects
        end
      end

      context "for a variant of another type" do
        let(:other_variant) { create(:type).default_variant }

        before { post :make_default, params: { type_id: type.id, id: other_variant.id } }

        it "does not find it, so the flag stays put" do
          expect(response).to have_http_status(:not_found)
          expect(other_variant.reload).not_to be_enabled_in_new_projects
        end
      end
    end

    describe "POST remove_default" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      before { post :remove_default, params: { type_id: type.id, id: variant.id } }

      it "clears the flag" do
        expect(response).to redirect_to(types_path)
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end

    describe "DELETE destroy" do
      let!(:variant) { create(:type_variant, type:) }

      before { delete :destroy, params: { type_id: type.id, id: variant.id } }

      it "deletes it and falls back to the types index" do
        expect(response).to redirect_to(types_path)
        expect(TypeVariant).not_to exist(id: variant.id)
      end
    end

    describe "returning to where the action was triggered" do
      let!(:variant) { create(:type_variant, type:) }
      let(:back_url) { type_variants_path(type_id: type.id) }

      it "sends make_default back to the variants tab" do
        post :make_default, params: { type_id: type.id, id: variant.id, back_url: }

        expect(response).to redirect_to(back_url)
      end

      it "sends remove_default back to the variants tab" do
        post :remove_default, params: { type_id: type.id, id: variant.id, back_url: }

        expect(response).to redirect_to(back_url)
      end

      it "sends destroy back to the variants tab" do
        delete :destroy, params: { type_id: type.id, id: variant.id, back_url: }

        expect(response).to redirect_to(back_url)
      end

      it "ignores a back_url pointing at another host" do
        post :make_default, params: { type_id: type.id, id: variant.id, back_url: "https://evil.example.com/types" }

        expect(response).to redirect_to(types_path)
      end
    end

    describe "POST convert_to_global" do
      let!(:variant) { create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Hardware") }

      it "detaches it from its project and falls back to the types index" do
        post :convert_to_global, params: { type_id: type.id, id: variant.id }

        expect(response).to redirect_to(types_path)
        expect(variant.reload.project_id).to be_nil
      end

      context "when a new name is no longer conflicting" do
        before { create(:type_variant, type:, variant_name: "Hardware") }

        it "renames the variant and detaches it in one step" do
          post :convert_to_global,
               params: { type_id: type.id, id: variant.id, type_variant: { variant_name: "Firmware" } }

          expect(response).to redirect_to(types_path)
          expect(variant.reload).to have_attributes(variant_name: "Firmware", project_id: nil)
        end
      end

      context "when the variant inherits from a project-specific variant" do
        before do
          variant.update!(workflows_source: create(:project_owned_type_variant, type:, project: variant.project,
                                                                                variant_name: "Sibling"))
        end

        it "refuses and leaves it project-owned" do
          post :convert_to_global, params: { type_id: type.id, id: variant.id }, format: :turbo_stream

          expect(variant.reload).to be_project_owned
        end
      end

      context "for a variant of another type" do
        let(:other_variant) { create(:project_owned_type_variant, project: create(:project)) }

        it "does not find it, so nothing is converted" do
          post :convert_to_global, params: { type_id: type.id, id: other_variant.id }

          expect(response).to have_http_status(:not_found)
          expect(other_variant.reload).to be_project_owned
        end
      end
    end

    describe "POST convert_to_global_rename" do
      let!(:variant) { create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Hardware") }

      # A global sibling already holds the name
      before { create(:type_variant, type:, variant_name: "Hardware") }

      it "advances to the confirmation dialog without yet touching the variant" do
        post :convert_to_global_rename,
             params: { type_id: type.id, id: variant.id, type_variant: { variant_name: "Firmware" } },
             format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(variant.reload).to have_attributes(variant_name: "Hardware")
        expect(variant).to be_project_owned
      end

      it "keeps the dialog open when the new name is taken too" do
        post :convert_to_global_rename,
             params: { type_id: type.id, id: variant.id, type_variant: { variant_name: "Hardware" } },
             format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(variant.reload.variant_name).to eq("Hardware")
      end

      it "keeps the dialog open when the new name is blank" do
        post :convert_to_global_rename,
             params: { type_id: type.id, id: variant.id, type_variant: { variant_name: "" } },
             format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(variant.reload.variant_name).to eq("Hardware")
      end
    end

    describe "GET convert_to_global_dialog" do
      let!(:variant) { create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Hardware") }

      it "opens the confirmation dialog when the variant can be converted as-is" do
        get :convert_to_global_dialog, params: { type_id: type.id, id: variant.id }, format: :turbo_stream

        expect(response.body).to include(WorkPackageTypes::Types::ConvertToGlobalDialogComponent::DIALOG_ID)
      end

      context "when a global sibling already carries the name" do
        before { create(:type_variant, type:, variant_name: "Hardware") }

        it "opens the rename dialog instead" do
          get :convert_to_global_dialog, params: { type_id: type.id, id: variant.id }, format: :turbo_stream

          expect(response.body).to include(WorkPackageTypes::Types::ConvertToGlobalRenameDialogComponent::DIALOG_ID)
        end
      end

      context "when the variant inherits from a project-specific variant" do
        before do
          variant.update!(workflows_source: create(:project_owned_type_variant, type:, project: variant.project,
                                                                                variant_name: "Sibling"))
        end

        it "refuses via a page reload and a flash, opening no dialog" do
          get :convert_to_global_dialog, params: { type_id: type.id, id: variant.id }, format: :turbo_stream

          expect(response.body).to include("reloadPage")
          expect(response.body).not_to include(WorkPackageTypes::Types::ConvertToGlobalDialogComponent::DIALOG_ID)
          expect(flash[:error].to_sentence).to include("inherits from a project-specific variant")
        end
      end
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }
    let(:variant) { type.default_variant }

    describe "POST make_default" do
      before { post :make_default, params: { type_id: type.id, id: variant.id } }

      it "is forbidden and leaves the flag untouched" do
        expect(response).to have_http_status(:forbidden)
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end

    describe "GET convert_to_global_dialog" do
      let(:variant) { create(:project_owned_type_variant, type:, project: create(:project)) }

      before { get :convert_to_global_dialog, params: { type_id: type.id, id: variant.id } }

      it "is forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST convert_to_global" do
      let(:variant) { create(:project_owned_type_variant, type:, project: create(:project)) }

      before { post :convert_to_global, params: { type_id: type.id, id: variant.id } }

      it "is forbidden and leaves the variant project-owned" do
        expect(response).to have_http_status(:forbidden)
        expect(variant.reload).to be_project_owned
      end
    end

    describe "POST convert_to_global_rename" do
      let(:variant) { create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Hardware") }

      before do
        post :convert_to_global_rename,
             params: { type_id: type.id, id: variant.id, type_variant: { variant_name: "Firmware" } }
      end

      it "is forbidden and leaves the name untouched" do
        expect(response).to have_http_status(:forbidden)
        expect(variant.reload.variant_name).to eq("Hardware")
      end
    end
  end
end
