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

RSpec.describe "API v3 Project favorite resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project, reload: true) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_project] }) }

  current_user { user }

  shared_examples "favoring a workspace" do
    describe "POST" do
      before do
        post favorite_path
      end

      it "responds with 204 No Content and marks as favorite", :aggregate_failures do
        expect(last_response).to have_http_status(204)
        expect(project.favorited_by?(user)).to be true
      end

      context "when project is already favorited" do
        before do
          project.set_favorited(user, favorited: true)
          post favorite_path
        end

        it "responds with 204 No Content and keeps project as is", :aggregate_failures do
          expect(last_response).to have_http_status(204)
          expect(project.favorited_by?(user)).to be true
        end
      end

      context "when user lacks permissions" do
        let(:project) { create(:project, public: false) }

        it "responds with 404 Not Found" do
          expect(last_response).to have_http_status(404)
        end
      end

      context "when user is anonymous and login not required",
              with_settings: { login_required: false } do
        let(:user) { User.anonymous }

        it "responds with 404 Not found" do
          expect(last_response).to have_http_status(404)
        end

        context "when project is public" do
          before do
            project.update!(public: true)
          end

          it "responds with 403 Forbidden" do
            expect(last_response).to have_http_status(404)
          end
        end
      end

      context "when user is anonymous and login required",
              with_settings: { login_required: true } do
        let(:user) { User.anonymous }

        it "responds with 401 Unauthorized" do
          expect(last_response).to have_http_status(401)
        end
      end
    end

    describe "DELETE" do
      before do
        project.set_favorited(user, favorited: true)
        delete favorite_path
      end

      it "responds with 204 No Content and removes favorite", :aggregate_failures do
        expect(last_response).to have_http_status(204)
        expect(project.favorited_by?(user)).to be false
      end

      context "when project is not favorited" do
        before do
          project.set_favorited(user, favorited: false)
          delete favorite_path
        end

        it "responds with 204 No Content, and keeps the project as is", :aggregate_failures do
          expect(last_response).to have_http_status(204)
          expect(project.favorited_by?(user)).to be false
        end
      end

      context "when user lacks permissions" do
        let(:project) { create(:project, public: false) }

        it "responds with 404 Not Found" do
          expect(last_response).to have_http_status(404)
        end
      end
    end
  end

  describe "api/v3/projects/:id/favorite" do
    include_examples "favoring a workspace" do
      let(:favorite_path) { "/api/v3/projects/#{project.id}/favorite" }
    end
  end

  describe "api/v3/workspaces/:id/favorite" do
    include_examples "favoring a workspace" do
      let(:favorite_path) { api_v3_paths.favor_workspace(project.id) }
    end
  end
end
