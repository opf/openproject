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

RSpec.describe "API v3 version's projects resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  current_user do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:role_without_permissions) { create(:project_role, permissions: []) }
  let(:project) { create(:project, public: false) }
  let(:program) { create(:program, public: false) }
  let(:portfolio) { create(:portfolio, public: false) }
  let(:inaccessible_project) { create(:project, public: false) }
  let(:version) { create(:version, project:) }

  subject(:response) { last_response }

  shared_examples "get workspace's versions" do
    context "logged in user with permissions" do
      before do
        # this is to be included
        create(:member, user: current_user,
                        project: program,
                        roles: [role])
        # this is to be included as the user is a member of the project, the
        # lack of permissions is irrelevant.
        create(:member, user: current_user,
                        project: portfolio,
                        roles: [role_without_permissions])
        # inaccessible_project should NOT be included
        inaccessible_project

        get get_path
      end

      it_behaves_like "API V3 collection response", 3, 3, "Portfolio" do
        let(:elements) { [portfolio, program, project] }
      end
    end

    context "logged in user without permissions" do
      let(:role) { role_without_permissions }

      before do
        get get_path
      end

      it_behaves_like "not found"
    end
  end

  describe "#GET /api/v3/versions/:id/projects" do
    it_behaves_like "get workspace's versions" do
      let(:get_path) { api_v3_paths.projects_by_version version.id }
    end
  end

  describe "#GET /api/v3/versions/:id/workspaces" do
    it_behaves_like "get workspace's versions" do
      let(:get_path) { api_v3_paths.workspaces_by_version version.id }
    end
  end
end
