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

RSpec.describe "Project custom fields drop", :skip_csrf, type: :rails_request do
  shared_let(:section_a) { create(:project_custom_field_section) }
  shared_let(:section_b) { create(:project_custom_field_section) }
  shared_let(:section_c) { create(:project_custom_field_section) }
  shared_let(:cf1) { create(:project_custom_field, project_custom_field_section: section_a) }
  shared_let(:cf2) { create(:project_custom_field, project_custom_field_section: section_a) }
  shared_let(:cf3) { create(:project_custom_field, project_custom_field_section: section_a) }
  shared_let(:cf4) { create(:project_custom_field, project_custom_field_section: section_b) }

  def drop(field, params)
    put drop_admin_settings_project_custom_field_path(field),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  context "as admin" do
    current_user { create(:admin) }

    it "reorders the field within its section after the anchor" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: cf1.id.to_s })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf3.column_name, cf2.column_name])
    end

    it "moves the field to the top of its section for a blank prev_id" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:ok)
      expect(section_a.reload.attribute_order).to eq([cf3.column_name, cf1.column_name, cf2.column_name])
    end

    it "moves the field across sections, updating both sections and the field's section" do
      drop(cf2, { list_type: "custom_field", list_id: section_b.id.to_s, prev_id: cf4.id.to_s })
      expect(response).to have_http_status(:ok)
      expect(section_b.reload.attribute_order).to eq([cf4.column_name, cf2.column_name])
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf3.column_name])
      expect(cf2.reload.custom_field_section_id).to eq(section_b.id)
    end

    it "moves the field into an empty section with a blank prev_id" do
      drop(cf3, { list_type: "custom_field", list_id: section_c.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:ok)
      expect(section_c.reload.attribute_order).to eq([cf3.column_name])
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_c.id)
    end

    it "422s without mutation for an unknown prev_id" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: "999999" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "422s without mutation for a self prev_id" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: cf3.id.to_s })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "422s without mutation for a prev_id from another section" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: cf4.id.to_s })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(section_b.reload.attribute_order).to eq([cf4.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "422s when prev_id is omitted entirely" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end

    it "422s for a wrong list_type" do
      drop(cf3, { list_type: "section", list_id: section_a.id.to_s, prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end

    it "422s for a blank list_id" do
      drop(cf3, { list_type: "custom_field", list_id: "", prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end

    it "422s without mutation for a collection-valued prev_id" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: [cf1.id.to_s] })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end

    it "422s without mutation for a collection-valued list_id" do
      drop(cf3, { list_type: "custom_field", list_id: [section_b.id.to_s], prev_id: "" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(section_b.reload.attribute_order).to eq([cf4.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end
  end

  context "as a non-admin" do
    current_user { create(:user) }

    it "is forbidden" do
      drop(cf3, { list_type: "custom_field", list_id: section_a.id.to_s, prev_id: cf1.id.to_s })
      expect(response).to have_http_status(:forbidden)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end
  end
end
