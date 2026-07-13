# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Sprint resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:other_project) { create(:project, public: false) }
  shared_let(:project_without_permission) { create(:project, public: false) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:other_sprint) { create(:sprint, project: other_project) }
  shared_let(:sprint_without_permission) { create(:sprint, project: project_without_permission) }

  let(:permissions) { %i[view_sprints] }

  current_user do
    create(:user,
           member_with_permissions: {
             project => permissions,
             other_project => permissions
           })
  end

  describe "GET /api/v3/sprints" do
    let(:get_path) { api_v3_paths.path_for(:sprints, filters:, page_size:, offset:) }
    let(:filters) { [] }
    let(:page_size) { nil }
    let(:offset) { nil }

    before do
      get get_path
    end

    context "for a user with view_sprints permission" do
      it_behaves_like "API V3 collection response", 2, 2, "Sprint" do
        let(:elements) { [other_sprint, sprint] }
      end
    end

    context "for a user without view_sprints permission" do
      let(:permissions) { [] }

      it_behaves_like "API V3 collection response", 0, 0, "Sprint"
    end

    context "for an anonymous user" do
      let(:current_user) { User.anonymous }

      it_behaves_like "unauthenticated access"
    end

    context "with a page_size parameter and offset parameter" do
      let(:page_size) { 1 }
      let(:offset) { 2 }

      it_behaves_like "API V3 collection response", 2, 1, "Sprint" do
        let(:elements) { [sprint] }
      end
    end

    context "with a definingWorkspace filter" do
      let(:filters) { [{ definingWorkspace: { operator: "=", values: [project.id.to_s] } }] }

      it_behaves_like "API V3 collection response", 1, 1, "Sprint" do
        let(:elements) { [sprint] }
      end
    end
  end
end
