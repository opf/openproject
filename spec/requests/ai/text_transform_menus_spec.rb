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

RSpec.describe "AI text transform menu", :skip_csrf, type: :rails_request do
  let(:frame_id) { "ai-text-transform-menu-abc123" }

  context "when logged in" do
    current_user { create(:user) }

    it "renders the menu shell pointing at the work package list endpoint" do
      get ai_text_transform_menu_path(frame_id:, work_package_id: 42)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame id="#{frame_id}">))
      expect(response.body).to include("/api/v3/work_packages/42/ai_text_transform_actions")
    end

    it "points at the project list endpoint for a new work package" do
      get ai_text_transform_menu_path(frame_id:, project_id: 3, type_id: 7)

      expect(response.body).to include("/api/v3/projects/3/ai_text_transform_actions?typeId=7")
    end

    it "falls back to the context-free list endpoint" do
      get ai_text_transform_menu_path(frame_id:)

      expect(response.body).to include(%(list-url-value="/api/v3/ai_text_transform_actions"))
    end

    it "rejects a frame id it did not expect" do
      get ai_text_transform_menu_path(frame_id: "evil\"><script>")

      expect(response).to have_http_status(:bad_request)
    end
  end

  context "when anonymous" do
    it "requires a login" do
      get ai_text_transform_menu_path(frame_id:)

      expect(response).not_to have_http_status(:ok)
      expect(response.body).not_to include("turbo-frame")
    end
  end
end
