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

require "spec_helper"

RSpec.describe "User custom field section fields drop", :skip_csrf, type: :rails_request do
  shared_let(:section_a) { create(:user_custom_field_section, attribute_order: %w[login]) }
  shared_let(:section_b) { create(:user_custom_field_section, attribute_order: %w[firstname]) }
  shared_let(:cf1) { create(:user_custom_field, user_custom_field_section: section_a) }
  shared_let(:cf2) { create(:user_custom_field, user_custom_field_section: section_a) }

  def drop(key, params)
    put drop_admin_settings_user_custom_field_section_field_path(key),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  context "as admin" do
    current_user { create(:admin) }

    it "reorders a custom field after another custom field" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: cf2.id.to_s })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq(["login", cf2.column_name, cf1.column_name])
    end

    it "reorders a built-in attribute after another built-in attribute" do
      section_a.update_column(:attribute_order, %w[login firstname])

      drop("firstname", { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq(%w[firstname login])
    end

    it "anchors a custom field after a built-in attribute" do
      drop(cf2.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "login" })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq(["login", cf2.column_name, cf1.column_name])
    end

    it "anchors a built-in attribute after a custom field" do
      drop("login", { list_type: "user_field", list_id: section_a.id.to_s, prev_id: cf1.id.to_s })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, "login", cf2.column_name])
    end

    it "moves a custom field across sections" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_b.id.to_s, prev_id: "firstname" })
      expect(response).to have_http_status(:ok)
      expect(section_b.reload.attribute_order).to eq(["firstname", cf1.column_name])
      expect(section_a.reload.attribute_order).to eq(["login", cf2.column_name])
      expect(cf1.reload.custom_field_section_id).to eq(section_b.id)
    end

    it "moves a built-in attribute across sections" do
      drop("login", { list_type: "user_field", list_id: section_b.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:ok)
      expect(section_b.reload.attribute_order).to eq(%w[login firstname])
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
    end

    it "422s without mutation for an unknown built-in key" do
      drop("not_a_real_attribute", { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s without mutation for a self prev_id" do
      drop("login", { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "login" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s without mutation for an anchor from another section" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "firstname" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s for a wrong list_type" do
      drop(cf1.id.to_s, { list_type: "section", list_id: section_a.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s for a blank list_id" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: "", prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s when prev_id is omitted entirely" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s without mutation for a key belonging to a different CustomField subtype" do
      project_section = create(:project_custom_field_section)
      foreign_field = create(:project_custom_field, project_custom_field_section: project_section)

      drop(foreign_field.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
      expect(foreign_field.reload.custom_field_section_id).to eq(project_section.id)
    end

    it "422s (not 500) for a key belonging to a CustomField subtype with no section at all" do
      sectionless_field = create(:wp_custom_field)

      drop(sectionless_field.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end

    it "422s without mutation for a prev_id belonging to a different CustomField subtype" do
      project_section = create(:project_custom_field_section)
      foreign_field = create(:project_custom_field, project_custom_field_section: project_section)

      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: foreign_field.id.to_s })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
      expect(cf1.reload.custom_field_section_id).to eq(section_a.id)
    end
  end

  context "as a non-admin" do
    current_user { create(:user) }

    it "is forbidden" do
      drop(cf1.id.to_s, { list_type: "user_field", list_id: section_a.id.to_s, prev_id: "login" })
      expect(response).to have_http_status(:forbidden)
      expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
    end
  end
end
