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

RSpec.describe PredefinedWorkPackageFilter do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  it "only publishes a new filter to selected projects and configured locations" do
    filter = described_class.create!(name: "Artefacts", project_overview: true, gantt: true)

    expect(described_class.active_in(project)).not_to include(filter)
    filter.set_active_in!(project, active: true)

    expect(described_class.active_in(project).at(:project_overview)).to include(filter)
    expect(described_class.active_in(project).at(:gantt)).to include(filter)
    expect(described_class.active_in(project).at(:work_packages)).not_to include(filter)
    expect(described_class.active_in(other_project)).not_to include(filter)
  end

  it "lists the same activated filter in both configured project modules" do
    filter = described_class.create!(name: "Artefacts", work_packages: true, gantt: true,
                                     query_properties: { "g" => "status", "f" => [] })
    filter.set_active_in!(project, active: true)

    work_packages = WorkPackages::Menu.new(project:, params: ActionController::Parameters.new)
    gantt = Gantt::Menu.new(project:, params: ActionController::Parameters.new)

    expect(work_packages.default_queries.map(&:title)).to include("Artefacts")
    expect(gantt.default_queries.map(&:title)).to include("Artefacts")
    expect(WorkPackages::Menu.new(project: other_project, params: ActionController::Parameters.new)
      .default_queries.map(&:title)).not_to include("Artefacts")
  end

  it "does not restore a deleted built-in filter when defaults are seeded again" do
    filter = described_class.find_by!(builtin_key: "assigned_to_me")

    filter.remove!
    described_class.seed_builtin_filters!

    expect(described_class.available).not_to include(filter)
    expect(described_class.active_in(project)).not_to include(filter)
  end

  it "keeps the built-in filters enabled by default and permits project overrides" do
    filter = described_class.find_or_create_by!(builtin_key: "assigned_to_me") do |builtin|
      builtin.work_packages = true
    end
    expect(described_class.active_in(project).at(:work_packages)).to include(filter)

    filter.set_active_in!(project, active: false)
    expect(described_class.active_in(project)).not_to include(filter)
    expect(described_class.active_in(other_project)).to include(filter)

    filter.set_active_in!(project, active: true)
    expect(described_class.active_in(project)).to include(filter)
    expect(filter.project_settings.where(project:).count).to eq(1)
  end
end
