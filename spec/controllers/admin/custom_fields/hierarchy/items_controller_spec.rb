# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Admin::CustomFields::Hierarchy::ItemsController, with_ee: [:custom_field_hierarchies] do
  let(:user) { create(:admin) }
  let(:custom_field) { create(:custom_field, field_format: "hierarchy") }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:root) { custom_field.hierarchy_root }
  let(:contract_class) { CustomFields::Hierarchy::InsertHierarchyItemContract }
  let!(:luke) { service.insert_item(contract_class:, parent: root, label: "luke").value! }

  current_user { user }

  context "when the user is not logged in" do
    let(:user) { User.anonymous }

    it "responds with forbidden" do
      get :index, params: { custom_field_id: custom_field.id }
      expect(response.status).to redirect_to(signin_url(back_url: custom_field_items_url(custom_field)))
    end
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    it "responds with forbidden" do
      get :index, params: { custom_field_id: custom_field.id }
      expect(response).to have_http_status :forbidden
    end
  end

  describe "GET #index" do
    it "renders the index page" do
      get :index, params: { custom_field_id: custom_field.id }
      expect(response).to be_successful
      expect(response).to render_template "index"
    end
  end

  describe "GET #show" do
    # yes, show action renders the index page
    it "renders the index page" do
      get :show, params: { custom_field_id: custom_field.id, id: luke.id }
      expect(response).to be_successful
      expect(response).to render_template "index"
    end
  end

  describe "GET #new" do
    it "renders the new page" do
      get :new, params: { custom_field_id: custom_field.id }
      expect(response).to be_successful
      expect(response).to render_template "new"
    end
  end

  describe "GET #edit" do
    it "renders the edit page" do
      get :edit, params: { custom_field_id: custom_field.id, id: luke.id }
      expect(response).to be_successful
      expect(response).to render_template "edit"
    end
  end

  describe "POST #create" do
    context "when validation successful" do
      it "creates a new item" do
        expect do
          post :create, params: { custom_field_id: custom_field.id, parent_id: root.id, label: "Leia", short: "L" }
        end.to change(CustomField::Hierarchy::Item, :count).by(1)
      end

      it "renders the create page" do
        post :create, params: { custom_field_id: custom_field.id, parent_id: root.id, label: "Leia", short: "L" }
        expect(response).to be_redirect
      end
    end

    context "when validation fails" do
      it "renders the new page" do
        post :create, params: { custom_field_id: custom_field.id }
        expect(response).to be_successful
        expect(response).to render_template "new"
      end
    end
  end

  describe "PUT #update" do
    context "when validation successful" do
      it "updates an item" do
        updated_name = "Luke Skywalker"

        expect do
          post :update, params: { custom_field_id: custom_field.id, id: luke.id, label: updated_name }
        end.to change { luke.reload.label }.from("luke").to(updated_name)
      end

      it "redirects" do
        post :update, params: { custom_field_id: custom_field.id, id: luke.id, label: "luke s." }
        expect(response).to be_redirect
      end
    end

    context "when validation fails" do
      before do
        allow(controller).to receive(:respond_with_turbo_streams).and_call_original
        allow(controller).to receive(:add_errors_to_edit_form).and_call_original
      end

      it "renders the errors on the page" do
        post :update, params: { custom_field_id: custom_field.id, id: luke.id, label: nil, format: :turbo_stream }

        expect(controller).to have_received(:respond_with_turbo_streams).once
        expect(controller).to have_received(:add_errors_to_edit_form).once
      end
    end
  end

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[luke]) }
    let!(:luke) { root.children.find_by!(label: "luke") }

    it "creates an item without a short" do
      post :create, params: { custom_field_id: custom_field.id, parent_id: root.id, label: "Leia", short: "L" }

      expect(root.children.find_by!(label: "Leia").short).to be_nil
    end

    it "updates an item without a short" do
      post :update, params: { custom_field_id: custom_field.id, id: luke.id, label: "Luke", short: "L" }

      expect(luke.reload).to have_attributes(label: "Luke", short: nil)
    end
  end

  describe "PUT #move" do
    before do
      contract_class = CustomFields::Hierarchy::InsertHierarchyItemContract
      service.insert_item(contract_class:, parent: root, label: "not relevant")
      service.insert_item(contract_class:, parent: root, label: "not important")
      service.insert_item(contract_class:, parent: root, label: "unused")
    end

    context "when it is successful" do
      it "redirects to the index" do
        post :move, params: { custom_field_id: custom_field.id, id: luke.id, new_sort_order: 3 }
        expect(response).to be_redirect
      end

      it "moves the item to the new position" do
        expect do
          post :move, params: { custom_field_id: custom_field.id, id: luke.id, new_sort_order: 2 }
        end.to change { luke.reload.sort_order }.from(0).to(1)
      end
    end

    context "when missing parameters" do
      it "fails with bad request" do
        post :move, params: { custom_field_id: custom_field.id, id: luke.id } # missing new_sort_order
        expect(response).to be_bad_request
      end
    end
  end

  describe "DELETE #destroy" do
    context "when validation successful" do
      it "deletes an item" do
        expect do
          post :destroy, params: { custom_field_id: custom_field.id, id: luke.id }
        end.to change(CustomField::Hierarchy::Item, :count).by(-1)
      end

      it "renders the update page" do
        post :destroy, params: { custom_field_id: custom_field.id, id: luke.id }
        expect(response).to be_no_content
      end
    end

    context "when validation fails" do
      it "renders the new page" do
        post :destroy, params: { custom_field_id: custom_field.id, id: -1337 }
        expect(response).to be_not_found
        expect(response).to render_template "common/error"
      end
    end
  end

  describe "GET #deletion_dialog" do
    it "renders the deletion dialog" do
      get :deletion_dialog, params: { custom_field_id: custom_field.id, id: luke.id }, as: :turbo_stream
      expect(response).to be_successful
    end
  end
end
