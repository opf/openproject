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

RSpec.describe "Project custom field sections drop", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:section_a) { create(:project_custom_field_section) }
  shared_let(:section_b) { create(:project_custom_field_section) }

  current_user { admin }

  def drop(section, params)
    put drop_admin_settings_project_custom_field_section_path(section),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  it "moves the section below the anchor" do
    drop(section_a, { list_type: "section", list_id: "", prev_id: section_b.id.to_s })
    expect(response).to have_http_status(:ok)
    expect(ProjectCustomFieldSection.order(:position).ids).to eq([section_b.id, section_a.id])
  end

  it "moves the section to the top for a blank prev_id" do
    drop(section_b, { list_type: "section", list_id: "", prev_id: "" })
    expect(response).to have_http_status(:ok)
    expect(ProjectCustomFieldSection.order(:position).ids).to eq([section_b.id, section_a.id])
  end

  it_behaves_like "a sortable list drop endpoint", list_id_scoped: false do
    let(:dragged_id) { section_a.id }
    let(:valid_drop_params) do
      { list_type: "section", list_id: "", prev_id: section_b.id.to_s }
    end

    def send_drop(params) = drop(section_a, params)

    def expect_unmoved
      expect(ProjectCustomFieldSection.order(:position).ids).to eq([section_a.id, section_b.id])
    end
  end

  it "morphs the sections list on success" do
    drop(section_a, { list_type: "section", list_id: "", prev_id: section_b.id.to_s })
    expect(response.body).to include('method="morph"')
  end
end
