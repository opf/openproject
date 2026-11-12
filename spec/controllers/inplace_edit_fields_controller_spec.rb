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

require "rails_helper"

RSpec.describe InplaceEditFieldsController do
  let(:user) { create(:user) }
  let(:model) { create(:project) }
  let(:attribute) { :description }
  let(:model_param) { "project" }

  let(:update_registry) do
    contract = double
    allow(contract).to receive(:new).and_return(double(writable?: true))
    registry = OpenProject::InplaceEdit::UpdateRegistry.new
    registry.register(Project, handler:, contract:)
    registry
  end

  before do
    allow(controller).to receive_messages(current_user: user, update_registry:)

    allow(Project)
      .to receive(:visible)
            .and_return(Project.all)
  end

  describe "GET #edit" do
    let(:handler) { double }

    it "returns a turbo stream response" do
      get :edit, params: {
        model: model_param,
        id: model.id,
        attribute:
      }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "GET #dialog" do
    let(:handler) { double }

    it "returns a turbo stream response with the dialog component" do
      get :dialog, params: {
        model: model_param,
        id: model.id,
        attribute:
      }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "PATCH #update" do
    let(:handler) { double(call: success) }

    context "when update is successful" do
      let(:success) { true }

      it "returns ok and renders success flash" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: {
            description: "New description"
          }
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when update fails" do
      let(:success) { false }

      it "returns unprocessable_entity and stays in edit mode" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: {
            description: ""
          }
        }, format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when successful and system_arguments contain a wrapper_id (dialog context)" do
      let(:handler) { double(call: true) }
      let(:wrapper_id) { "#my-inplace-dialog" }

      it "includes a turbo stream to close the dialog" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { description: "New description" },
          system_arguments: OpenProject::InplaceEdit::SystemArguments.sign(wrapper_id:)
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("my-inplace-dialog")
      end

      it "ignores unsigned system arguments" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { description: "New description" },
          system_arguments: { wrapper_id: }.to_json
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("my-inplace-dialog")
      end
    end

    context "when attribute is a custom field (hash params via fields_for)" do
      let(:handler) { double(call: true) }
      let(:custom_field) { create(:project_custom_field) }
      let(:attribute) { custom_field.attribute_name.to_sym }

      before do
        allow(ProjectCustomField).to receive(:visible).and_return(ProjectCustomField.all)
      end

      it "accepts custom_field_values hash params and returns ok" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { custom_field_values: { custom_field.id.to_s => "Option A" } }
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
      end
    end

    context "when attribute is a custom field (array params from FilterableTreeView)" do
      let(:handler) { double(call: true) }
      let(:custom_field) { create(:project_custom_field) }
      let(:attribute) { custom_field.attribute_name.to_sym }

      before do
        allow(ProjectCustomField).to receive(:visible).and_return(ProjectCustomField.all)
      end

      it "accepts custom_field_values array params and returns ok" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { custom_field_values: ["{\"value\":\"42\"}", ""] }
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
      end
    end

    context "when updating a custom field with calculated dependents" do
      let(:handler) { double(call: true) }
      let(:custom_field) { create(:integer_project_custom_field, projects: [model]) }
      let(:attribute) { custom_field.attribute_name.to_sym }
      let!(:calculated_field) do
        create(
          :calculated_value_project_custom_field,
          :skip_validations,
          formula: "{{cf_#{custom_field.id}}} * 2",
          projects: [model]
        )
      end

      before do
        allow(ProjectCustomField).to receive(:visible).and_return(ProjectCustomField.all)
      end

      it "refreshes dependent fields when stable-key arguments are omitted" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { custom_field_values: { custom_field.id.to_s => "42" } }
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        stream_targets = Nokogiri::HTML.fragment(response.body).css("turbo-stream").pluck("targets")
        expect(stream_targets)
          .to include("[data-inplace-edit-stable-key='project_#{model.id}_#{calculated_field.attribute_name}']")
      end

      context "with stable-key arguments of the dependent field" do
        let(:stable_key) { "project_#{model.id}_#{calculated_field.attribute_name}" }

        before do
          patch :update, params: {
            model: model_param,
            id: model.id,
            attribute:,
            project: { custom_field_values: { custom_field.id.to_s => "42" } },
            stable_key_system_arguments: { stable_key => stable_key_arguments }
          }, format: :turbo_stream
        end

        context "when they are signed" do
          let(:stable_key_arguments) { OpenProject::InplaceEdit::SystemArguments.sign(test_selector: "calculated-field") }

          it "renders the dependent field with them" do
            expect(response.body).to include('data-test-selector="calculated-field"')
          end
        end

        context "when they are unsigned" do
          let(:stable_key_arguments) { { test_selector: "calculated-field" }.to_json }

          it "renders the dependent field without them" do
            expect(response.body).not_to include('data-test-selector="calculated-field"')
          end
        end

        context "when they are nested parameters" do
          let(:stable_key_arguments) { { test_selector: "calculated-field" } }

          it "renders the dependent field without them", :aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to include('data-test-selector="calculated-field"')
          end
        end
      end

      it "renders the dependent fields when the stable-key arguments are not a hash" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { custom_field_values: { custom_field.id.to_s => "42" } },
          stable_key_system_arguments: "not a hash"
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
      end
    end

    context "when no update handler is registered" do
      let(:handler) { nil }

      it "returns 404" do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { description: "Foo" }
        }, format: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #reset" do
    let(:handler) { double }

    it "renders the component in view mode" do
      post :reset, params: {
        model: model_param,
        id: model.id,
        attribute:
      }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "project custom field visibility guard" do
    let(:handler) { double }

    context "when the model is a project and the custom field is not visible to the user" do
      let(:custom_field) { create(:project_custom_field) }
      let(:attribute) { custom_field.attribute_name.to_sym }

      before do
        allow(ProjectCustomField)
          .to receive(:visible)
          .and_return(ProjectCustomField.none)
      end

      it "returns 404" do
        get :dialog, params: {
          model: model_param,
          id: model.id,
          attribute:
        }, format: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the model is not a project" do
      let(:non_project_model) { create(:user) }

      let(:update_registry) do
        registry = OpenProject::InplaceEdit::UpdateRegistry.new
        contract = double
        allow(contract).to receive(:new).and_return(double(writable?: true))
        registry.register(User, handler:, contract:)
        registry
      end

      before do
        allow(controller).to receive_messages(current_user: user, update_registry:)
        allow(User).to receive(:visible).and_return(User.where(id: non_project_model.id))
        allow(controller).to receive(:respond_with_dialog) # skip component rendering for non-project model
      end

      it "does not apply the project custom field visibility check for a custom field attribute" do
        get :dialog, params: {
          model: "user",
          id: non_project_model.id,
          attribute: :custom_field_1
        }, format: :turbo_stream

        expect(response).not_to have_http_status(:not_found)
      end
    end
  end

  describe "attribute allowlist" do
    let(:handler) { double(call: true) }
    let(:attribute) { :destroy }

    it "returns 404 on edit and keeps the project", :aggregate_failures do
      get :edit, params: { model: model_param, id: model.id, attribute: }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(model.id)
    end

    it "returns 404 on dialog and keeps the project", :aggregate_failures do
      get :dialog, params: { model: model_param, id: model.id, attribute: }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(model.id)
    end

    it "returns 404 on reset and keeps the project", :aggregate_failures do
      get :reset, params: { model: model_param, id: model.id, attribute: }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(model.id)
    end

    it "returns 404 on update and keeps the project", :aggregate_failures do
      patch :update, params: { model: model_param, id: model.id, attribute:, project: { destroy: "1" } },
                     format: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(model.id)
    end

    context "when the system arguments override a registered attribute" do
      let(:attribute) { :description }

      it "renders the registered attribute and keeps the project", :aggregate_failures do
        get :reset, params: {
          model: model_param,
          id: model.id,
          attribute:,
          system_arguments: { attribute: "destroy" }.to_json
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Project).to exist(model.id)
      end
    end

    context "when the system arguments of a calculated dependent override its attribute" do
      let(:custom_field) { create(:integer_project_custom_field, projects: [model]) }
      let(:attribute) { custom_field.attribute_name.to_sym }
      let!(:calculated_field) do
        create(:calculated_value_project_custom_field,
               :skip_validations,
               formula: "{{cf_#{custom_field.id}}} * 2",
               projects: [model])
      end

      before do
        allow(ProjectCustomField).to receive(:visible).and_return(ProjectCustomField.all)
      end

      it "renders the dependent field and keeps the project", :aggregate_failures do
        patch :update, params: {
          model: model_param,
          id: model.id,
          attribute:,
          project: { custom_field_values: { custom_field.id.to_s => "42" } },
          stable_key_system_arguments: {
            "project_#{model.id}_#{calculated_field.attribute_name}" => { attribute: "destroy" }.to_json
          }
        }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Project).to exist(model.id)
      end
    end
  end

  describe "model resolution errors" do
    let(:handler) { double }

    it "returns 404 for unsupported model" do
      get :edit, params: {
        model: "invalid_model",
        id: 123,
        attribute:
      }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing record" do
      get :edit, params: {
        model: model_param,
        id: -1,
        attribute:
      }, format: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end
end
