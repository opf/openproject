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

RSpec.describe "Admin custom fields dedicated pages",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }

  shared_examples "a dedicated custom field admin page" do |factory:, model:, route:|
    let(:url_helpers) { Rails.application.routes.url_helpers }
    let(:index_path) { url_helpers.public_send(:"#{route}s_path") }
    let(:new_path) { url_helpers.public_send(:"new_#{route}_path", field_format: "string") }
    let(:edit_path) { ->(cf) { url_helpers.public_send(:"edit_#{route}_path", cf) } }
    let(:member_path) { ->(cf) { url_helpers.public_send(:"#{route}_path", cf) } }
    let!(:custom_field) { create(factory, name: "Existing field") }

    it "denies non-admins" do
      login_as non_admin
      get index_path
      expect(response).to have_http_status(:forbidden)
    end

    context "as an admin" do
      before { login_as admin }

      it "lists the fields" do
        get index_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Existing field")
      end

      it "renders the new form" do
        get new_path

        expect(response).to have_http_status(:ok)
      end

      it "creates a field and redirects to its edit page" do
        expect do
          post index_path, params: { type: model.name, custom_field: { name: "New field", field_format: "string" } }
        end.to change(model, :count).by(1)

        created = model.last
        expect(created.name).to eq("New field")
        expect(response).to redirect_to(edit_path.call(created))
      end

      it "re-renders the form with a validation error on invalid input" do
        expect do
          post index_path, params: { type: model.name, custom_field: { name: "", field_format: "string" } }
        end.not_to change(model, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Capybara.string(response.body)).to have_text("Name can't be blank.")
      end

      it "renders the edit form" do
        get edit_path.call(custom_field)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Existing field")
      end

      it "updates the field" do
        put member_path.call(custom_field), params: { custom_field: { name: "Renamed" } }

        expect(response).to be_redirect
        expect(custom_field.reload.name).to eq("Renamed")
      end

      it "destroys the field" do
        deletable = create(factory)

        expect do
          delete member_path.call(deletable)
        end.to change(model, :count).by(-1)
      end
    end
  end

  describe "work package custom fields" do
    it_behaves_like "a dedicated custom field admin page",
                    factory: :work_package_custom_field,
                    model: WorkPackageCustomField,
                    route: "admin_settings_work_package_custom_field"
  end

  describe "version custom fields" do
    it_behaves_like "a dedicated custom field admin page",
                    factory: :version_custom_field,
                    model: VersionCustomField,
                    route: "admin_settings_version_custom_field"
  end

  describe "group custom fields" do
    it_behaves_like "a dedicated custom field admin page",
                    factory: :group_custom_field,
                    model: GroupCustomField,
                    route: "admin_settings_group_custom_field"
  end

  describe "time entry custom fields" do
    it_behaves_like "a dedicated custom field admin page",
                    factory: :time_entry_custom_field,
                    model: TimeEntryCustomField,
                    route: "admin_settings_time_entry_custom_field"
  end
end
