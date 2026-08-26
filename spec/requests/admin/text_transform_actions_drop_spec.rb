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

RSpec.describe "Text transform actions drop", :skip_csrf,
               type: :rails_request, with_flag: { ai_text_transform_actions: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:action_a) { create(:ai_text_transform_action) }
  shared_let(:action_b) { create(:ai_text_transform_action) }

  current_user { admin }

  def drop(action, params)
    put drop_admin_text_transform_action_path(action),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def ordered_ids
    AI::TextTransformAction.ordered.ids
  end

  it "moves the action below the anchor" do
    drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: action_b.id.to_s })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq([action_b.id, action_a.id])
  end

  it "moves the action to the top for a blank prev_id" do
    drop(action_b, { list_type: "text_transform_action", list_id: "", prev_id: "" })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq([action_b.id, action_a.id])
  end

  it "422s without mutation for an unknown anchor" do
    drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: "999999" })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s when prev_id is omitted entirely" do
    drop(action_a, { list_type: "text_transform_action", list_id: "" })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s for a wrong list_type" do
    drop(action_a, { list_type: "section", list_id: "", prev_id: "" })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s for a nonblank list_id" do
    drop(action_a, { list_type: "text_transform_action", list_id: action_b.id.to_s, prev_id: "" })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s without mutation for a collection-valued prev_id" do
    drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: [action_b.id.to_s] })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s without mutation for an empty collection prev_id" do
    drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: [""] })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "422s for a collection-valued list_id" do
    drop(action_a, { list_type: "text_transform_action", list_id: [""], prev_id: "" })
    expect(response).to have_http_status(:unprocessable_entity)
    expect(ordered_ids).to eq([action_a.id, action_b.id])
  end

  it "morphs the list on success" do
    drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: action_b.id.to_s })
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('target="text_transform_actions_list"')
    expect(response.body).to include('method="morph"')
  end

  context "when not an admin" do
    current_user { create(:user) }

    it "is forbidden" do
      drop(action_a, { list_type: "text_transform_action", list_id: "", prev_id: action_b.id.to_s })
      expect(response).to have_http_status(:forbidden)
      expect(ordered_ids).to eq([action_a.id, action_b.id])
    end
  end
end
