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

RSpec.describe "API::V3::WorkPackages::AvailableProjectsOnEditAPI" do
  include API::V3::Utilities::PathHelper

  let(:edit_role) do
    create(:project_role, permissions: %i[edit_work_packages
                                          view_work_packages])
  end
  let(:move_role) do
    create(:project_role, permissions: [:move_work_packages])
  end
  let(:project) { create(:project) }
  let(:target_project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  current_user do
    create(:user,
           member_with_roles: { project => edit_role }).tap do |user|
      create(:member,
             user:,
             project: target_project,
             roles: [move_role])
    end
  end

  before do
    get api_v3_paths.available_projects_on_edit(work_package.id)
  end

  context "with the necessary permissions" do
    it_behaves_like "API V3 collection response", 1, 1, "Project" do
      let(:elements) { [target_project] }
    end
  end

  context "without the edit_work_packages permission" do
    let(:edit_role) do
      create(:project_role, permissions: [:view_work_packages])
    end

    it_behaves_like "unauthorized access"
  end
end
