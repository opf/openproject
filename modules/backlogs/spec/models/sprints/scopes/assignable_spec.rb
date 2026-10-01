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

RSpec.describe Sprints::Scopes::Assignable do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:in_planning_sprint_in_project) { create(:sprint, project:, status: "in_planning") }
  shared_let(:active_sprint_in_project) { create(:sprint, project:, status: "active") }
  shared_let(:completed_sprint_in_project) { create(:sprint, project:, status: "completed") }
  shared_let(:in_planning_sprint_in_other_project) { create(:sprint, project: other_project, status: "in_planning") }
  shared_let(:active_sprint_in_other_project) { create(:sprint, project: other_project, status: "active") }
  shared_let(:completed_sprint_in_other_project) { create(:sprint, project: other_project, status: "completed") }
  # WPs only exist so that the sharing aspect is (rudimentarily) tested.
  # It is not the goal of this spec to retest the whole of .for_project
  shared_let(:wp_in_other_project_in_planning_sprint) do
    create(:work_package, sprint: in_planning_sprint_in_other_project, project:)
  end
  shared_let(:wp_in_other_project_in_active_sprint) do
    create(:work_package, sprint: active_sprint_in_other_project, project:)
  end
  shared_let(:wp_in_other_project_in_completed_sprint) do
    create(:work_package, sprint: completed_sprint_in_other_project, project:)
  end
  shared_let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages]) }
  shared_let(:user) do
    create(:user,
           member_with_roles: { project => role, other_project => role })
  end

  context "when the user has permission to view sprints in the project" do
    it "returns sprints that are in_planning or active and shared or native to the project" do
      expect(Sprint.assignable(project:,
                               user:))
        .to contain_exactly(in_planning_sprint_in_project,
                            active_sprint_in_project,
                            in_planning_sprint_in_other_project,
                            active_sprint_in_other_project)
    end

    it "returns sprints that are in_planning or active and native to the project" do
      expect(Sprint.assignable(project: other_project,
                               user:))
        .to contain_exactly(in_planning_sprint_in_other_project,
                            active_sprint_in_other_project)
    end
  end

  context "when the user lacks permission to view sprints in the project" do
    before do
      role.remove_permission!(:view_sprints)
    end

    it "returns no sprints" do
      expect(Sprint.assignable(project:,
                               user:))
        .to be_empty
    end
  end
end
