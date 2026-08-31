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

RSpec.describe "Admin text transform actions", :skip_csrf,
               type: :rails_request, with_flag: { ai_text_transform_actions: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }

  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  current_user { admin }

  describe "GET /admin/text_transform_actions" do
    let!(:action) { create(:ai_text_transform_action, label: "Fix grammar") }

    it "renders the list with the setting toggle" do
      get admin_text_transform_actions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fix grammar")
      expect(response.body).to include("Enable text transform actions")
    end
  end

  describe "GET /admin/text_transform_actions/new" do
    it "renders the form" do
      get new_admin_text_transform_action_path

      expect(response).to have_http_status(:ok)
      expect(page).to have_text("New text transform action")
    end

    it "associates the types label, caption and select panel button" do
      get new_admin_text_transform_action_path

      label = page.find("label", text: "Work package types", visible: :all)
      button = page.find("[data-test-selector='text-transform-action-select-types']", visible: :all)

      expect(label[:for]).to eq(button[:id])
      expect(button[:"aria-describedby"]).to be_present
    end
  end

  describe "POST /admin/text_transform_actions" do
    it "creates an action with types for the specific scope" do
      post admin_text_transform_actions_path,
           params: {
             ai_text_transform_action: {
               label: "Translate",
               prompt: "Translate the text.",
               usage_scope: "specific_work_package_types",
               injects_type_template: "1",
               type_ids: ["", type.id.to_s]
             }
           }

      expect(response).to redirect_to(admin_text_transform_actions_path)

      action = AI::TextTransformAction.find_by!(label: "Translate")
      expect(action).to be_specific_work_package_types
      expect(action).to be_injects_type_template
      expect(action.types).to eq([type])
      expect(action.position).to eq(1)
    end

    it "drops stale type ids and template injection for the everywhere scope" do
      post admin_text_transform_actions_path,
           params: {
             ai_text_transform_action: {
               label: "Everywhere",
               prompt: "Do something.",
               usage_scope: "everywhere",
               injects_type_template: "1",
               type_ids: ["", type.id.to_s]
             }
           }

      expect(response).to redirect_to(admin_text_transform_actions_path)

      action = AI::TextTransformAction.find_by!(label: "Everywhere")
      expect(action.types).to be_empty
      expect(action).not_to be_injects_type_template
    end

    it "rejects a specific scope without types" do
      post admin_text_transform_actions_path,
           params: {
             ai_text_transform_action: {
               label: "Translate",
               prompt: "Translate the text.",
               usage_scope: "specific_work_package_types",
               type_ids: [""]
             }
           }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(page).to have_text("Work package types can't be blank")
      expect(AI::TextTransformAction.count).to eq(0)
    end
  end

  describe "GET /admin/text_transform_actions/:id/edit" do
    let!(:action) { create(:ai_text_transform_action, label: "Fix grammar") }

    it "renders the form with the action's values" do
      get edit_admin_text_transform_action_path(action)

      expect(response).to have_http_status(:ok)
      expect(page).to have_field("Label", with: "Fix grammar")
    end
  end

  describe "PATCH /admin/text_transform_actions/:id" do
    let!(:action) { create(:ai_text_transform_action, :for_specific_types) }

    it "updates the action and clears types when the scope is no longer specific" do
      patch admin_text_transform_action_path(action),
            params: {
              ai_text_transform_action: {
                label: "Renamed",
                usage_scope: "all_work_package_types",
                type_ids: action.type_ids.map(&:to_s)
              }
            }

      expect(response).to redirect_to(admin_text_transform_actions_path)

      action.reload
      expect(action.label).to eq("Renamed")
      expect(action).to be_all_work_package_types
      expect(action.types).to be_empty
    end

    it "re-renders the form on validation errors" do
      patch admin_text_transform_action_path(action),
            params: { ai_text_transform_action: { label: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(action.reload.label).not_to eq("")
    end
  end

  describe "GET /admin/text_transform_actions/:id/deletion_dialog" do
    let!(:action) { create(:ai_text_transform_action, label: "Make concise") }

    it "renders the danger dialog" do
      get deletion_dialog_admin_text_transform_action_path(action), headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Delete text transform action")
      expect(response.body).to include("Make concise")
    end
  end

  describe "DELETE /admin/text_transform_actions/:id" do
    let!(:action) { create(:ai_text_transform_action, :for_specific_types) }

    it "deletes the action and its type assignments" do
      delete admin_text_transform_action_path(action)

      expect(response).to redirect_to(admin_text_transform_actions_path)
      expect(AI::TextTransformAction.where(id: action.id)).not_to exist
      expect(AI::TextTransformActionType.where(ai_text_transform_action_id: action.id)).not_to exist
    end
  end

  describe "POST /admin/text_transform_actions/:id/toggle" do
    let!(:action) { create(:ai_text_transform_action, active: true) }

    it "deactivates the action" do
      post toggle_admin_text_transform_action_path(action), params: { value: "0" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(action.reload).not_to be_active
    end

    it "activates the action" do
      action.update!(active: false)

      post toggle_admin_text_transform_action_path(action), params: { value: "1" }

      expect(response).to have_http_status(:ok)
      expect(action.reload).to be_active
    end
  end

  describe "PUT /admin/text_transform_actions/enable_all and disable_all" do
    let!(:active_action) { create(:ai_text_transform_action, active: true) }
    let!(:inactive_action) { create(:ai_text_transform_action, active: false) }

    it "disables all actions and re-renders the list" do
      put disable_all_admin_text_transform_actions_path, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="text_transform_actions_list"')
      expect(AI::TextTransformAction.active).to be_empty
    end

    it "enables all actions" do
      put enable_all_admin_text_transform_actions_path, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(AI::TextTransformAction.active.ids).to contain_exactly(active_action.id, inactive_action.id)
    end
  end

  describe "POST /admin/text_transform_actions/toggle_setting", :settings_reset do
    it "enables the setting and re-renders the toggle" do
      post toggle_setting_admin_text_transform_actions_path, params: { value: "1" }, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="text_transform_actions_setting"')
      expect(response.body).to include('target="text_transform_actions_list"')
      expect(Setting.ai_text_transform_actions_enabled?).to be(true)
    end

    it "disables the setting" do
      Setting.ai_text_transform_actions_enabled = true

      post toggle_setting_admin_text_transform_actions_path, params: { value: "0" }, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(Setting.ai_text_transform_actions_enabled?).to be(false)
    end
  end

  context "when not an admin" do
    let!(:action) { create(:ai_text_transform_action) }

    current_user { create(:user) }

    it "forbids listing" do
      get admin_text_transform_actions_path
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids toggling an action" do
      post toggle_admin_text_transform_action_path(action), params: { value: "0" }
      expect(response).to have_http_status(:forbidden)
      expect(action.reload).to be_active
    end

    it "forbids toggling the setting" do
      post toggle_setting_admin_text_transform_actions_path, params: { value: "1" }
      expect(response).to have_http_status(:forbidden)
      expect(Setting.ai_text_transform_actions_enabled?).to be(false)
    end
  end

  context "when the feature flag is inactive", with_flag: { ai_text_transform_actions: false } do
    let!(:action) { create(:ai_text_transform_action) }

    it "responds with 404 for the list" do
      get admin_text_transform_actions_path
      expect(response).to have_http_status(:not_found)
    end

    it "responds with 404 for mutations without changing anything" do
      post toggle_admin_text_transform_action_path(action), params: { value: "0" }
      expect(response).to have_http_status(:not_found)
      expect(action.reload).to be_active
    end
  end
end
