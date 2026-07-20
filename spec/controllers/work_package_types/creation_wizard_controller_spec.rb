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

RSpec.describe WorkPackageTypes::CreationWizardController, with_flag: { subtypes: true } do
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
      it "creates the sub-type and advances to the next step" do
        expect do
          post :create, params: { type: { name: "Critical", parent_id: parent_type.id } }
        end.to change(Type, :count).by(1)

        subtype = Type.find_by!(name: "Critical")
        expect(subtype.parent).to eq(parent_type)
        expect(response).to redirect_to(type_creation_wizard_path(subtype, step: :form_configuration))
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

    describe "existing sub-type" do
      shared_let(:subtype) { create(:type, name: "Critical", parent: parent_type) }

      describe "GET show" do
        before { get :show, params: { type_id: subtype.id, step: :projects } }

        it { expect(response).to have_http_status(:ok) }

        it "renders the requested step" do
          expect(response.body).to include(I18n.t("types.creation_wizard.steps.projects"))
        end
      end

      describe "GET show for every step" do
        WorkPackageTypes::Wizard::Steps.all.each do |step|
          it "renders the #{step} step without error" do
            get :show, params: { type_id: subtype.id, step: }

            expect(response).to have_http_status(:ok)
          end
        end
      end

      describe "PATCH update on the details step" do
        it "updates and advances to the next step" do
          patch :update, params: { type_id: subtype.id, step: :details, type: { name: "Blocker" } }

          expect(subtype.reload.own_name).to eq("Blocker")
          expect(response).to redirect_to(type_creation_wizard_path(subtype, step: :form_configuration))
        end
      end

      describe "PATCH update on the workflows step" do
        shared_let(:workflow_source) { create(:type, name: "Task") }
        shared_let(:status) { create(:status) }
        shared_let(:role) { create(:project_role) }
        shared_let(:workflow) do
          create(:workflow, type: workflow_source, role:, old_status: status, new_status: status)
        end

        it "copies workflows from the chosen source and advances" do
          expect do
            patch :update, params: { type_id: subtype.id, step: :workflows,
                                     type: { copy_workflow_from: workflow_source.id } }
          end.to change { subtype.reload.workflows.count }.from(0).to(1)

          expect(response).to redirect_to(type_creation_wizard_path(subtype, step: :automations))
        end

        it "advances without copying when no source is chosen" do
          patch :update, params: { type_id: subtype.id, step: :workflows, type: { copy_workflow_from: "" } }

          expect(subtype.reload.workflows).to be_empty
          expect(response).to redirect_to(type_creation_wizard_path(subtype, step: :automations))
        end
      end

      describe "PATCH update on the last step" do
        before { patch :update, params: { type_id: subtype.id, step: WorkPackageTypes::Wizard::Steps.last } }

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

  context "when the sub-types feature is disabled", with_flag: { subtypes: false } do
    let(:user) { create(:admin) }

    describe "GET new" do
      before { get :new, params: { parent_id: parent_type.id } }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end
