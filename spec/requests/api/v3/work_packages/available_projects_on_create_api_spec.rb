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
require "rack/test"

RSpec.describe API::V3::WorkPackages::AvailableProjectsOnCreateAPI do
  include API::V3::Utilities::PathHelper

  let(:add_role) do
    create(:project_role, permissions: [:add_work_packages])
  end
  let(:project) { create(:project) }
  let(:type_id) { nil }

  current_user do
    create(:user,
           member_with_roles: { project => add_role })
  end

  context "with a type filter present" do
    let(:type) { create(:type) }
    let(:type_id) { type.id }
    let(:project_with_type) { create(:project, types: [type]) }
    let(:member) do
      create(:member, principal: current_user, project: project_with_type, roles: [add_role])
    end

    before do
      project
      project_with_type
      member

      params = [type_id: { operator: "=", values: [type_id] }]
      escaped = CGI.escape(JSON.dump(params))

      get "#{api_v3_paths.available_projects_on_create}?filters=#{escaped}"
    end

    it_behaves_like "API V3 collection response", 1, 1, "Project" do
      let(:elements) { [project_with_type] }
    end
  end

  describe "with a single project" do
    before do
      project

      get api_v3_paths.available_projects_on_create
    end

    context "with the necessary permissions" do
      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "without any add_work_packages permission" do
      let(:add_role) do
        create(:project_role, permissions: [])
      end

      it_behaves_like "unauthorized access"
    end
  end
end
