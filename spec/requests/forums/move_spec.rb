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
