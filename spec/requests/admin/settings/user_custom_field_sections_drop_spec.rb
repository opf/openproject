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

RSpec.describe "User custom field sections drop", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:section_a) { create(:user_custom_field_section) }
  shared_let(:section_b) { create(:user_custom_field_section) }

  current_user { admin }

  def drop(section, prev_id: nil, list_type: "user_custom_field_section", list_id: "")
    put drop_admin_settings_user_custom_field_section_path(section),
        params: { list_type:, list_id:, prev_id: }.compact,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  it "moves the section below the anchor" do
    drop(section_a, prev_id: section_b.id.to_s)
    expect(response).to have_http_status(:ok)
    expect(UserCustomFieldSection.order(:position).ids).to eq([section_b.id, section_a.id])
  end

  it "moves the section to the top for a blank prev_id" do
    drop(section_b, prev_id: "")
    expect(response).to have_http_status(:ok)
    expect(UserCustomFieldSection.order(:position).ids).to eq([section_b.id, section_a.id])
  end

  it "morphs the sections list on success" do
    drop(section_a, prev_id: section_b.id.to_s)
    expect(response.body).to include('method="morph"')
  end

  it "keeps every section's fields and their order when moving a section" do
    field_a = create(:user_custom_field, user_custom_field_section: section_a)
    field_b = create(:user_custom_field, user_custom_field_section: section_b)
    section_a.update_column(:attribute_order, ["login", field_a.column_name])
    section_b.update_column(:attribute_order, [field_b.column_name, "firstname"])

    drop(section_a, prev_id: section_b.id.to_s)

    expect(response).to have_http_status(:ok)
    expect(UserCustomFieldSection.order(:position).ids).to eq([section_b.id, section_a.id])
    expect(section_a.reload.attribute_order).to eq(["login", field_a.column_name])
    expect(section_b.reload.attribute_order).to eq([field_b.column_name, "firstname"])
    expect(field_a.reload.custom_field_section_id).to eq(section_a.id)
    expect(field_b.reload.custom_field_section_id).to eq(section_b.id)
  end

  {
    "an unknown anchor" => -> { { prev_id: "999999" } },
    "a self-referencing anchor" => -> { { prev_id: section_a.id.to_s } },
    "an anchor outside the user section scope" => -> { { prev_id: create(:project_custom_field_section).id.to_s } },
    "prev_id omitted entirely" => -> { {} },
    "a wrong list_type" => -> { { list_type: "custom_field", prev_id: "" } },
    "a nonblank list_id" => -> { { list_id: section_b.id.to_s, prev_id: "" } },
    "a collection-valued prev_id" => -> { { prev_id: [section_b.id.to_s] } },
    "an empty collection prev_id" => -> { { prev_id: [""] } },
    "a collection-valued list_id" => -> { { list_id: [""], prev_id: "" } }
  }.each do |description, params|
    it "422s without mutation for #{description}" do
      drop(section_a, **instance_exec(&params))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(UserCustomFieldSection.order(:position).ids).to eq([section_a.id, section_b.id])
    end
  end

  it "is forbidden for a non-admin" do
    non_admin = create(:user)
    login_as(non_admin)

    drop(section_a, prev_id: section_b.id.to_s)
    expect(response).to have_http_status(:forbidden)
  end
end
