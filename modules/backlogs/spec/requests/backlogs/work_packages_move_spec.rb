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

RSpec.describe "Backlogs work package move", :skip_csrf, type: :rails_request do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:user) { create(:admin) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:story_one) { create(:work_package, status:, sprint:, project:) }
  shared_let(:story_two) { create(:work_package, status:, sprint:, project:) }

  current_user { user }

  describe "PUT #move" do
    context "with an optimistic same-list reorder" do
      it "responds 204 without a body and persists the reorder" do
        put move_project_backlogs_work_package_path(project, story_one),
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { prev_id: story_two.id, list_type: "sprint", list_id: sprint.id, optimistic: "true" }

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(story_one.reload.position).to be > story_two.reload.position
      end
    end

    context "with a same-list reorder without the optimistic param (menu move)" do
      it "responds with a turbo-stream frame reload and persists the reorder" do
        put move_project_backlogs_work_package_path(project, story_one),
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { prev_id: story_two.id, list_type: "sprint", list_id: sprint.id }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("backlogs_container")
        expect(story_one.reload.position).to be > story_two.reload.position
      end
    end

    context "with a same-list reorder and optimistic explicitly false" do
      it "responds with a turbo-stream frame reload, not a 204, and persists the reorder" do
        put move_project_backlogs_work_package_path(project, story_one),
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { prev_id: story_two.id, list_type: "sprint", list_id: sprint.id, optimistic: "false" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("backlogs_container")
        expect(story_one.reload.position).to be > story_two.reload.position
      end
    end

    context "with an optimistic cross-list move" do
      it "responds with a turbo-stream frame reload and persists the move" do
        put move_project_backlogs_work_package_path(project, story_one),
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { prev_id: "", list_type: "inbox", list_id: "", optimistic: "true" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("backlogs_container")
        expect(story_one.reload.sprint_id).to be_nil
      end
    end

    context "with a failing move" do
      it "responds with an error flash stream" do
        put move_project_backlogs_work_package_path(project, story_one),
            headers: { "Accept" => "text/vnd.turbo-stream.html" },
            params: { list_type: "unknown", list_id: "1" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include(
          I18n.t(:notice_unsuccessful_update_with_reason,
                 reason: I18n.t("backlogs.stories.update_service.invalid_target_type"))
        )
      end
    end
  end
end
