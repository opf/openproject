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

RSpec.describe "Admin user custom field semantic keys",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section) }
  shared_let(:position_field) do
    create(:user_custom_field, name: "Position", field_format: "string", user_custom_field_section: section)
  end
  shared_let(:role_field) do
    create(:user_custom_field, name: "Role", field_format: "string", user_custom_field_section: section)
  end

  before { login_as(admin) }

  describe "GET index" do
    it "shows tab navigation on the attributes tab without the semantic keys form" do
      get admin_settings_user_custom_fields_path

      expect(response).to have_http_status(:ok)
      # The semantic-keys tab is linked from the nav, but its form is not on the attributes tab.
      expect(response.body).to include("tab=semantic_keys")
      expect(response.body).not_to include('name="semantic_keys[job_title]"')
    end

    it "renders the semantic keys assignment form on the semantic_keys tab" do
      role_field.update!(semantic_key: "job_title")

      get admin_settings_user_custom_fields_path(tab: :semantic_keys)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="semantic_keys[job_title]"')
      # The currently assigned field is pre-selected
      expect(response.body).to match(/<option(?=[^>]*\bselected\b)(?=[^>]*value="#{role_field.id}")[^>]*>/)
    end
  end

  describe "PATCH semantic_keys (update_semantic_keys)" do
    it "assigns the chosen custom field to the semantic key" do
      patch semantic_keys_admin_settings_user_custom_fields_path,
            params: { semantic_keys: { "job_title" => position_field.id.to_s } }

      expect(response).to redirect_to(admin_settings_user_custom_fields_path(tab: :semantic_keys))
      expect(position_field.reload.semantic_key).to eq("job_title")
    end

    it "moves the assignment from a previous holder to the new field" do
      position_field.update!(semantic_key: "job_title")

      patch semantic_keys_admin_settings_user_custom_fields_path,
            params: { semantic_keys: { "job_title" => role_field.id.to_s } }

      expect(position_field.reload.semantic_key).to be_nil
      expect(role_field.reload.semantic_key).to eq("job_title")
    end

    it "clears the assignment when the blank option is chosen" do
      position_field.update!(semantic_key: "job_title")

      patch semantic_keys_admin_settings_user_custom_fields_path,
            params: { semantic_keys: { "job_title" => "" } }

      expect(position_field.reload.semantic_key).to be_nil
    end

    it "ignores unknown semantic keys" do
      patch semantic_keys_admin_settings_user_custom_fields_path,
            params: { semantic_keys: { "manager" => position_field.id.to_s } }

      expect(position_field.reload.semantic_key).to be_nil
    end
  end

  describe "the per-field edit form" do
    it "no longer renders a semantic key select" do
      get edit_admin_settings_user_custom_field_path(position_field)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('name="custom_field[semantic_key]"')
    end
  end
end
