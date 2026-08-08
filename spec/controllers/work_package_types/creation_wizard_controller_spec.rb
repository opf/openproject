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

RSpec.describe WorkPackageTypes::CreationWizardController, with_flag: { type_variants: true } do
  render_views

  shared_let(:parent_type) { create(:type, name: "Bug") }

  before { login_as user }

  context "with admin access" do
    let(:user) { create(:admin) }

    describe "GET new" do
      before { get :new, params: { parent_id: parent_type.id } }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template "show" }

      it "renders the details step" do
        expect(response.body).to include(I18n.t("types.creation_wizard.steps.details"))
      end
    end

    describe "POST create" do
      it "creates the variant and advances to the next step" do
        expect do
          post :create, params: { type: { name: "Critical", parent_id: parent_type.id } }
        end.to change(Type, :count).by(1)

        variant = Type.find_by!(name: "Critical")
        expect(variant.parent).to eq(parent_type)
        expect(response).to redirect_to(type_creation_wizard_path(variant, step: :defaults))
      end

      context "with invalid params" do
        it "does not create and re-renders the details step" do
          expect do
            post :create, params: { type: { name: "", parent_id: parent_type.id } }
          end.not_to change(Type, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "existing variant" do
      shared_let(:variant) { create(:type, name: "Critical", parent: parent_type) }
      shared_let(:role) { create(:project_role) }

      describe "GET show" do
        before { get :show, params: { type_id: variant.id, step: :projects } }

        it { expect(response).to have_http_status(:ok) }

        it "renders the requested step" do
          expect(response.body).to include(I18n.t("types.creation_wizard.steps.projects"))
        end
      end

      describe "GET show for every step" do
        WorkPackageTypes::Wizard::Steps.all.each do |step|
          it "renders the #{step} step without error" do
            get :show, params: { type_id: variant.id, step: }

            expect(response).to have_http_status(:ok)
          end
        end
      end

      describe "GET show with an unrecognised step" do
        it "falls back to the first step" do
          get :show, params: { type_id: variant.id, step: "does-not-exist" }

          expect(assigns(:current_step)).to eq(WorkPackageTypes::Wizard::Steps.first)
        end
      end

      describe "PATCH update on the details step" do
        it "updates and advances to the next step" do
          patch :update, params: { type_id: variant.id, step: :details, type: { name: "Blocker" } }

          expect(variant.reload.own_name).to eq("Blocker")
          expect(response).to redirect_to(type_creation_wizard_path(variant, step: :defaults))
        end
      end

      describe "PATCH update on the workflows step" do
        # The wizard step only advances as the matrix saves via its own turbo endpoint
        it "advances to the next step" do
          patch :update, params: { type_id: variant.id, step: :workflows }

          expect(response).to redirect_to(type_creation_wizard_path(variant, step: :projects))
        end
      end

      describe "PATCH update on the last step" do
        before { patch :update, params: { type_id: variant.id, step: WorkPackageTypes::Wizard::Steps.last } }

        it { expect(response).to redirect_to(types_path) }

        it { expect(flash[:notice]).to eq(I18n.t("types.creation_wizard.success")) }
      end
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }

    describe "GET new" do
      before { get :new, params: { parent_id: parent_type.id } }

      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    let(:user) { create(:admin) }

    describe "GET new" do
      before { get :new, params: { parent_id: parent_type.id } }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end
