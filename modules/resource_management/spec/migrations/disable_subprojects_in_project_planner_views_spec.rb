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
require Rails.root.join("modules/resource_management/db/migrate/20261127145724_disable_subprojects_in_project_planner_views")

RSpec.describe DisableSubprojectsInProjectPlannerViews, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) { create(:user) }
  shared_let(:project_planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:global_planner) { create(:resource_planner, project: nil, principal: user) }

  let!(:project_list) do
    ResourceWorkPackageList.create!(name: "List", parent: project_planner, project:, principal: user)
  end
  let!(:project_timeline) do
    ResourceWorkPackageTimeline.create!(name: "Timeline", parent: project_planner, project:, principal: user)
  end
  let!(:global_list) do
    ResourceWorkPackageList.create!(name: "Global list", parent: global_planner, project: nil, principal: user)
  end
  let!(:unrelated_query) { create(:query, project:, include_subprojects: true) }

  before do
    [project_list, project_timeline, global_list].each do |view|
      view.update!(query: view.build_default_query.tap do |query|
        query.name = view.name
        query.include_subprojects = true
      end)
    end
  end

  it "stops the queries of project planner views from including subprojects" do
    migrate

    expect(project_list.query.reload.include_subprojects).to be(false)
    expect(project_timeline.query.reload.include_subprojects).to be(false)
  end

  it "leaves the queries of global planner views untouched" do
    migrate

    expect(global_list.query.reload.include_subprojects).to be(true)
  end

  it "leaves work package queries outside of resource planners untouched" do
    migrate

    expect(unrelated_query.reload.include_subprojects).to be(true)
  end
end
