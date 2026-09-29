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

  before { login_as user }

  context "with admin access" do
    let(:user) { create(:admin) }

    describe "GET new" do
      before { get :new }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template "show" }

      it "renders the details step" do
        expect(response.body).to include(I18n.t("types.creation_wizard.steps.details"))
      end
    end

    describe "POST create" do
      it "creates the type and advances to the next step" do
        expect do
          post :create, params: { type: { name: "Critical" } }
        end.to change(Type, :count).by(1)

        type = Type.find_by!(name: "Critical")
        expect(response).to redirect_to(type_creation_wizard_path(type, step: :defaults))
      end

      context "with invalid params" do
        it "does not create and re-renders the details step" do
          expect do
            post :create, params: { type: { name: "" } }
          end.not_to change(Type, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "existing type" do
      shared_let(:type) { create(:type, name: "Critical") }
      shared_let(:role) { create(:project_role) }

      describe "GET show" do
        before { get :show, params: { type_id: type.id, step: :projects } }

        it { expect(response).to have_http_status(:ok) }

        it "renders the requested step" do
          expect(response.body).to include(I18n.t("types.creation_wizard.steps.projects"))
        end
      end

      describe "GET show for every step" do
        WorkPackageTypes::Wizard::Steps.all.each do |step|
          it "renders the #{step} step without error" do
            get :show, params: { type_id: type.id, step: }

            expect(response).to have_http_status(:ok)
          end
        end
      end

      describe "GET show with an unrecognised step" do
        it "falls back to the first step" do
          get :show, params: { type_id: type.id, step: "does-not-exist" }

          expect(assigns(:current_step)).to eq(WorkPackageTypes::Wizard::Steps.first)
        end
      end

      describe "PATCH update on the details step" do
        it "updates and advances to the next step" do
          patch :update, params: { type_id: type.id, step: :details, type: { name: "Blocker" } }

          expect(type.reload.name).to eq("Blocker")
          expect(response).to redirect_to(type_creation_wizard_path(type, step: :defaults))
        end
      end

      describe "PATCH update on the workflows step" do
        # The wizard step only advances as the matrix saves via its own turbo endpoint
        it "advances to the next step" do
          patch :update, params: { type_id: type.id, step: :workflows }

          expect(response).to redirect_to(type_creation_wizard_path(type, step: :projects))
        end
      end

      describe "PATCH update on the last step" do
        before { patch :update, params: { type_id: type.id, step: WorkPackageTypes::Wizard::Steps.last } }

        it { expect(response).to redirect_to(types_path) }

        it { expect(flash[:notice]).to eq(I18n.t("types.creation_wizard.success")) }
      end

      describe "returning to where the wizard was entered from" do
        let(:back_url) { type_variants_path(type_id: type.id) }

        it "carries the back_url from step to step" do
          patch :update, params: { type_id: type.id, step: :details, type: { name: "Blocker" }, back_url: }

          expect(response).to redirect_to(type_creation_wizard_path(type, step: :defaults, back_url:))
        end

        it "returns there once the wizard finishes" do
          patch :update, params: { type_id: type.id, step: WorkPackageTypes::Wizard::Steps.last, back_url: }

          expect(response).to redirect_to(back_url)
          expect(flash[:notice]).to eq(I18n.t("types.creation_wizard.success"))
        end

        it "offers the cancel button the same target" do
          get :show, params: { type_id: type.id, step: :details, back_url: }

          expect(response.body).to include(CGI.escapeHTML(back_url))
        end

        it "drops a back_url pointing at another host" do
          patch :update, params: { type_id: type.id, step: WorkPackageTypes::Wizard::Steps.last,
                                   back_url: "https://evil.example.com/types" }

          expect(response).to redirect_to(types_path)
        end
      end
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }

    describe "GET new" do
      before { get :new }

      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    let(:user) { create(:admin) }

    describe "GET new" do
      before { get :new }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  context "when adding a variant from inside a project" do
    shared_let(:type) { create(:type, name: "Critical") }
    shared_let(:project) { create(:project, types: [type]) }

    let(:user) { create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] }) }

    describe "GET new" do
      before { get :new, params: { in_project_id: project.id, type_id: type.id } }

      it { expect(response).to have_http_status(:ok) }

      context "when the type does not allow project-specific variants" do
        before do
          type.update!(allow_project_variants: false)
          get :new, params: { in_project_id: project.id, type_id: type.id }
        end

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end
