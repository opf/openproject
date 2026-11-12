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
require "rack/test"

RSpec.describe "API v3 Project Configuration resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => [:view_project] }) }

  current_user { user }

  describe "GET /api/v3/projects/:id/configuration" do
    let(:path) { api_v3_paths.project_configuration(project.id) }

    subject(:response) do
      get path
      last_response
    end

    context "when user can view project" do
      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "returns Configuration type" do
        expect(response.body)
          .to be_json_eql("Configuration".to_json)
          .at_path("_type")
      end

      it "includes self link to project configuration" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.project_configuration(project.id).to_json)
          .at_path("_links/self/href")
      end

      it "includes global configuration properties", with_settings: { per_page_options: "20, 100" } do
        expect(response.body).to have_json_path("maximumAttachmentFileSize")
        expect(response.body).to have_json_path("perPageOptions")
        expect(response.body).to have_json_path("availableFeatures")
        expect(response.body)
          .to be_json_eql([20, 100].to_json)
          .at_path("perPageOptions")
      end

      context "when enabled_internal_comments is true" do
        before do
          project.update!(enabled_internal_comments: true)
        end

        it "returns enabledInternalComments as true" do
          expect(response.body)
            .to be_json_eql(true.to_json)
            .at_path("enabledInternalComments")
        end
      end

      context "when enabled_internal_comments is true but enterprise token does not allow it", with_ee: [] do
        before do
          project.update!(enabled_internal_comments: true)
        end

        it "returns enabledInternalComments as true (project setting)" do
          expect(response.body)
            .to be_json_eql(true.to_json)
            .at_path("enabledInternalComments")
        end

        it "does not include internalComments in availableFeatures" do
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["availableFeatures"]).not_to include("internalComments")
        end
      end

      context "when enabled_internal_comments is false" do
        before do
          project.update!(enabled_internal_comments: false)
        end

        it "returns enabledInternalComments as false" do
          expect(response.body)
            .to be_json_eql(false.to_json)
            .at_path("enabledInternalComments")
        end
      end

      context "when enabled_internal_comments is nil (default)" do
        before do
          # Ensure project.enabled_internal_comments is nil
          project.settings["enabled_internal_comments"] = nil
          project.save!
        end

        it "returns enabledInternalComments as false" do
          expect(response.body)
            .to be_json_eql(false.to_json)
            .at_path("enabledInternalComments")
        end
      end
    end

    context "when user cannot view project" do
      let(:other_user) { create(:user) }

      current_user { other_user }

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
