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

RSpec.describe "Roles drop", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:role_a) { create(:project_role, name: "Alpha") }
  shared_let(:role_b) { create(:project_role, name: "Beta") }

  current_user { admin }

  def drop(role, params)
    put drop_role_path(role), params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def ordered_ids
    Role.where(id: [role_a.id, role_b.id]).order(:position).ids
  end

  it "moves the role below the anchor" do
    drop(role_a, { list_type: "role", list_id: "", prev_id: role_b.id.to_s })

    expect(response).to have_http_status(:no_content)
    expect(ordered_ids).to eq([role_b.id, role_a.id])
  end

  it "moves the role to the top for a blank prev_id" do
    drop(role_b, { list_type: "role", list_id: "", prev_id: "" })

    expect(response).to have_http_status(:no_content)
    expect(ordered_ids).to eq([role_b.id, role_a.id])
  end

  it_behaves_like "a sortable list drop endpoint", list_id_scoped: false do
    let(:dragged_id) { role_a.id }
    let(:valid_drop_params) { { list_type: "role", list_id: "", prev_id: role_b.id.to_s } }

    def send_drop(params) = drop(role_a, params)

    def expect_unmoved = expect(ordered_ids).to eq([role_a.id, role_b.id])
  end

  it "422s without mutation for a builtin role, which keeps its place in the list" do
    builtin = create(:non_member)

    drop(builtin, { list_type: "role", list_id: "", prev_id: role_a.id.to_s })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([role_a.id, role_b.id])
  end

  it "422s without mutation for an anchor that is a builtin role" do
    builtin = create(:non_member)

    drop(role_a, { list_type: "role", list_id: "", prev_id: builtin.id.to_s })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([role_a.id, role_b.id])
  end

  context "when not an admin" do
    current_user { create(:user) }

    it "is forbidden" do
      drop(role_a, { list_type: "role", list_id: "", prev_id: role_b.id.to_s })

      expect(response).to have_http_status(:forbidden)
      expect(ordered_ids).to eq([role_a.id, role_b.id])
    end
  end
end
