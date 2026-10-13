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

RSpec.describe "Forum reordering", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_messages manage_forums] }) }
  shared_let(:general) { create(:forum, project:, name: "General") }
  shared_let(:support) { create(:forum, project:, name: "Support") }
  shared_let(:offtopic) { create(:forum, project:, name: "Off-topic") }

  current_user { manager }

  before do
    [general, support, offtopic].each_with_index { |forum, index| forum.update_column(:position, index + 1) }
  end

  def forum_order = project.forums.reload.map(&:name)

  describe "PUT /projects/:project_id/forums/:id/move" do
    let(:drop_params) { { list_type: "forum", list_id: "", prev_id: "" } }

    it "moves the forum in the requested direction" do
      put move_project_forum_path(project, general), params: { forum: { move_to: "lowest" } }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(forum_order).to eq(["Support", "Off-topic", "General"])
    end

    it "morphs the forums list and confirms the update", :aggregate_failures do
      put move_project_forum_path(project, offtopic), params: { forum: { move_to: "highest" } }, as: :turbo_stream

      expect(response.body).to include('target="forums-index-component"')
      expect(response.body).to include('method="morph"')
      expect(response.body).to include("Successful update.")
    end

    it "refuses an unknown direction without changing the order", :aggregate_failures do
      put move_project_forum_path(project, offtopic), params: { forum: { move_to: "sideways" } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Forum could not be moved.")
      expect(forum_order).to eq(["General", "Support", "Off-topic"])
    end

    it "moves the forum to the top for a blank anchor" do
      put move_project_forum_path(project, offtopic), params: drop_params, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(forum_order).to eq(["Off-topic", "General", "Support"])
    end

    it "moves down after an anchor" do
      put move_project_forum_path(project, general), params: drop_params.merge(prev_id: offtopic.id), as: :turbo_stream

      expect(forum_order).to eq(["Support", "Off-topic", "General"])
    end

    it "moves up after an anchor" do
      put move_project_forum_path(project, offtopic), params: drop_params.merge(prev_id: general.id), as: :turbo_stream

      expect(forum_order).to eq(["General", "Off-topic", "Support"])
    end

    it "refuses an anchor from another project without changing either order", :aggregate_failures do
      foreign = create(:forum, name: "Foreign")

      put move_project_forum_path(project, general), params: drop_params.merge(prev_id: foreign.id), as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("The item cannot be moved to the requested position.")
      expect(forum_order).to eq(["General", "Support", "Off-topic"])
    end

    {
      "unknown anchor" => { list_type: "forum", list_id: "", prev_id: "999999" },
      "wrong list type" => { list_type: "status", list_id: "", prev_id: "" },
      "missing list type" => { list_id: "", prev_id: "" },
      "nonblank list ID" => { list_type: "forum", list_id: "1", prev_id: "" },
      "array anchor" => { list_type: "forum", list_id: "", prev_id: [""] }
    }.each do |description, request_params|
      it "refuses #{description} without changing order", :aggregate_failures do
        put move_project_forum_path(project, offtopic), params: request_params, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(forum_order).to eq(["General", "Support", "Off-topic"])
      end
    end

    it "refuses a self-anchor without changing order" do
      put move_project_forum_path(project, support), params: drop_params.merge(prev_id: support.id), as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(forum_order).to eq(["General", "Support", "Off-topic"])
    end

    context "without the manage forums permission" do
      current_user { create(:user, member_with_permissions: { project => %i[view_messages] }) }

      it "forbids reordering" do
        put move_project_forum_path(project, offtopic), params: { forum: { move_to: "highest" } }, as: :turbo_stream

        expect(response).to have_http_status(:forbidden)
        expect(forum_order).to eq(["General", "Support", "Off-topic"])
      end
    end
  end
end
