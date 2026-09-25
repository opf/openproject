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

  def sidebar_menu_links(body)
    Nokogiri::HTML5(body).css("#menu-sidebar a[href]").map { URI(it["href"]).path }
  end

  it "renders the admin menu entry" do
    get admin_index_path

    expect(sidebar_menu_links(response.body)).to include(admin_labels_path)
  end

  describe "GET /admin/labels/search", with_settings: { per_page_options: "1 5 10" } do
    before { create_list(:label, 2) }

    it "renders pagination links that target the index action, not the search action" do
      get search_admin_labels_path, params: { per_page: 1 }, headers: turbo_stream_headers

      expect(response.body).to include("#{admin_labels_path}?")
      expect(response.body).not_to include("#{search_admin_labels_path}?")
    end
  end

  describe "POST /admin/labels" do
    it "redirects to the page containing the new label in the default alphabetical order",
       with_settings: { per_page_options: "2 5 10" } do
      create(:label, name: "Alpha")
      create(:label, name: "Bravo")
      create(:label, name: "Charlie")

      post admin_labels_path, params: { label: { name: "Zulu" }, per_page: 2 }

      expect(response).to redirect_to(admin_labels_path(page: 2))
      expect(Label.find_by!(name: "Zulu").author).to eq(admin)
    end
  end

  describe "PATCH /admin/labels/:id" do
    let!(:label) { create(:label, name: "Bug") }

    it "redirects to the page the renamed label sorts on",
       with_settings: { per_page_options: "2 5 10" } do
      create(:label, name: "Alpha")
      create(:label, name: "Charlie")

      patch admin_label_path(label), params: { label: { name: "Zulu" }, per_page: 2 }

      expect(response).to redirect_to(admin_labels_path(page: 2))
    end
  end

  describe "DELETE /admin/labels/:id" do
    let!(:label) { create(:label) }

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

      expect(sidebar_menu_links(response.body)).not_to include(admin_labels_path)
    end
  end
end
