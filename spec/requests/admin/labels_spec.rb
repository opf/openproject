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

RSpec.describe "Admin labels", :skip_csrf,
               type: :rails_request, with_flag: { work_package_labels: true } do
  shared_let(:admin) { create(:admin) }

  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  current_user { admin }

  describe "GET /admin/labels" do
    context "with labels" do
      let!(:used) { create(:label, name: "Bug") }
      let!(:unused) { create(:label, name: "Feature") }

      before { create_list(:labeling, 2, label: used) }

      it "lists the labels with their usage count" do
        get admin_labels_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bug")
        expect(response.body).to include("Feature")
        expect(response.body).to include("2 work packages")
      end

      it "renders a dash for a label without any usage" do
        get admin_labels_path

        row = Nokogiri::HTML5.fragment(response.body).at_css("[data-test-selector='label-row-#{unused.id}']")
        expect(row.at_css("[data-test-selector='label-usage']").text.strip).to eq("-")
      end
    end

    context "without any labels" do
      it "renders the blank slate" do
        get admin_labels_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No labels yet")
      end
    end

    it "renders the admin menu entry" do
      get admin_labels_path

      expect(response.body).to include("Labels")
    end
  end

  describe "GET /admin/labels/search", with_settings: { per_page_options: "1 5 10" } do
    let!(:matching) { create(:label, name: "urgent-bug") }
    let!(:other) { create(:label, name: "docs-update") }

    it "returns a turbo_stream response" do
      get search_admin_labels_path, params: { per_page: 1 }, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "narrows the list to labels matching the name filter" do
      filters = [{ name: { operator: "~", values: ["urgent"] } }].to_json

      get search_admin_labels_path, params: { filters: }, headers: turbo_stream_headers

      expect(response.body).to include(%(data-test-selector="label-row-#{matching.id}"))
      expect(response.body).not_to include(%(data-test-selector="label-row-#{other.id}"))
    end

    it "renders pagination links that target the index action, not the search action" do
      get search_admin_labels_path, params: { per_page: 1 }, headers: turbo_stream_headers

      expect(response.body).not_to include("#{search_admin_labels_path}?")
    end
  end

  describe "GET /admin/labels/new_dialog" do
    it "renders the create dialog" do
      get new_dialog_admin_labels_path, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create label")
    end
  end

  describe "GET /admin/labels/:id/edit_dialog" do
    let!(:label) { create(:label, name: "Machine Learning") }

    it "renders the rename dialog prefilled with the current name" do
      get edit_dialog_admin_label_path(label), headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rename &quot;Machine Learning&quot;").or include("Rename \"Machine Learning\"")
    end
  end

  describe "GET /admin/labels/:id/deletion_dialog" do
    let!(:label) { create(:label, name: "Machine Learning") }

    it "renders the danger dialog" do
      get deletion_dialog_admin_label_path(label), headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Delete this label?")
      expect(response.body).to include(
        "This will remove the label <strong>Machine Learning</strong> from all work packages in all projects."
      )
    end
  end

  describe "POST /admin/labels" do
    it "creates the label authored by the current user and redirects to the index" do
      post admin_labels_path, params: { label: { name: "Regression" } }

      expect(response).to redirect_to(admin_labels_path)

      label = Label.find_by!(name: "Regression")
      expect(label.author).to eq(admin)
    end

    it "redirects to the page containing the new label in the default alphabetical order",
       with_settings: { per_page_options: "2 5 10" } do
      create(:label, name: "Alpha")
      create(:label, name: "Bravo")
      create(:label, name: "Charlie")

      post admin_labels_path, params: { label: { name: "Zulu" }, per_page: 2 }

      expect(response).to redirect_to(admin_labels_path(page: 2))
    end

    it "rejects a blank name" do
      post admin_labels_path, params: { label: { name: "" } }, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Label.count).to eq(0)
    end

    it "rejects a case-insensitive duplicate name" do
      create(:label, name: "Bug")

      post admin_labels_path, params: { label: { name: "BUG" } }, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("A label with this name already exists. Please use another one.")
      expect(Label.where(name: "BUG")).not_to exist
    end
  end

  describe "PATCH /admin/labels/:id" do
    let!(:label) { create(:label, name: "Bug") }

    it "renames the label and redirects to the index" do
      patch admin_label_path(label), params: { label: { name: "Defect" } }

      expect(response).to redirect_to(admin_labels_path)
      expect(label.reload.name).to eq("Defect")
    end

    it "rejects a duplicate name" do
      create(:label, name: "Feature")

      patch admin_label_path(label), params: { label: { name: "Feature" } }, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("A label with this name already exists. Please use another one.")
      expect(label.reload.name).to eq("Bug")
    end
  end

  describe "DELETE /admin/labels/:id" do
    let!(:label) { create(:label) }
    let!(:labeling) { create(:labeling, label:) }

    it "removes the label and its labelings" do
      delete admin_label_path(label)

      expect(response).to redirect_to(admin_labels_path)
      expect(Label.where(id: label.id)).not_to exist
      expect(Labeling.where(id: labeling.id)).not_to exist
    end

    it "keeps the label and flashes the error when the delete service fails" do
      errors = ActiveModel::Errors.new(label).tap { |e| e.add(:base, "cannot be deleted right now") }
      service = instance_double(Labels::DeleteService, call: ServiceResult.failure(errors:))
      allow(Labels::DeleteService).to receive(:new).and_return(service)

      delete admin_label_path(label)

      expect(response).to redirect_to(admin_labels_path)
      expect(flash[:error]).to include("cannot be deleted right now")
      expect(Label.where(id: label.id)).to exist
    end
  end

  context "when not an admin" do
    let!(:label) { create(:label) }

    current_user { create(:user) }

    it "forbids listing" do
      get admin_labels_path
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids creating a label" do
      post admin_labels_path, params: { label: { name: "Nope" } }
      expect(response).to have_http_status(:forbidden)
      expect(Label.where(name: "Nope")).not_to exist
    end
  end

  context "when the feature flag is inactive", with_flag: { work_package_labels: false } do
    let!(:label) { create(:label) }

    it "responds with 404 for the list" do
      get admin_labels_path
      expect(response).to have_http_status(:not_found)
    end

    it "responds with 404 for create and creates nothing" do
      post admin_labels_path, params: { label: { name: "Nope" } }
      expect(response).to have_http_status(:not_found)
      expect(Label.where(name: "Nope")).not_to exist
    end

    it "responds with 404 for a member route" do
      get deletion_dialog_admin_label_path(label)
      expect(response).to have_http_status(:not_found)
    end

    it "does not render the admin menu entry" do
      get admin_index_path
      expect(response.body).not_to include(">Labels<")
    end
  end
end
