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

RSpec.describe ResourcePlannerViews::WorkPackageTimeline::ResourceCellComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:view) { ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user) }
  shared_let(:work_package) do
    create(:work_package, project:, subject: "Develop route optimization", estimated_hours: 80)
  end

  before { login_as(user) }

  it "renders the subject, type and the allocation summary" do
    allocation = build_stubbed(:resource_allocation, entity: work_package, allocated_time: 72 * 60)

    render_inline(described_class.new(work_package:, allocations: [allocation],
                                      project:, resource_planner: planner, view:))

    expect(page).to have_text("Develop route optimization")
    expect(page).to have_text(/#{work_package.type.name}/i)
    expect(page).to have_text("72")
    expect(page).to have_text("90%")
  end

  def remove_path(target_view)
    remove_work_package_project_resource_planner_view_path(
      project, planner, target_view, work_package_id: work_package.id
    )
  end

  def move_path(target_view, direction:)
    move_work_package_project_resource_planner_view_path(
      project, planner, target_view, work_package_id: work_package.id, direction:
    )
  end

  context "with an automatically filtered view" do
    it "offers no remove action in the context menu" do
      render_inline(described_class.new(work_package:, allocations: [],
                                        project:, resource_planner: planner, view:))

      expect(page).to have_no_css("form[action='#{remove_path(view)}']", visible: :all)
    end
  end

  context "with a manually hand-picked view" do
    let(:manual_query) do
      Query.new_default(project:, user:).tap do |q|
        q.name = "q"
        q.add_filter("manual_sort", "ow", [])
        q.sort_criteria = [%w[manual_sorting asc]]
        q.save!
      end
    end
    let(:manual_view) do
      ResourceWorkPackageTimeline.create!(name: "Manual", parent: planner, project:, principal: user, query: manual_query)
    end

    it "offers a remove action linked to the remove route" do
      render_inline(described_class.new(work_package:, allocations: [],
                                        project:, resource_planner: planner, view: manual_view))

      expect(page).to have_css("form[action='#{remove_path(manual_view)}']", visible: :all)
      expect(page).to have_text("Remove")
    end

    it "offers all move directions for a middle row" do
      render_inline(described_class.new(work_package:, allocations: [],
                                        project:, resource_planner: planner, view: manual_view,
                                        first: false, last: false))

      expect(page).to have_text("Move")
      %w[top up down bottom].each do |direction|
        expect(page).to have_css("form[action='#{move_path(manual_view, direction:)}']", visible: :all)
      end
    end

    it "hides upward moves for the first row" do
      render_inline(described_class.new(work_package:, allocations: [],
                                        project:, resource_planner: planner, view: manual_view,
                                        first: true, last: false))

      expect(page).to have_no_css("form[action='#{move_path(manual_view, direction: 'top')}']", visible: :all)
      expect(page).to have_no_css("form[action='#{move_path(manual_view, direction: 'up')}']", visible: :all)
      expect(page).to have_css("form[action='#{move_path(manual_view, direction: 'down')}']", visible: :all)
    end

    it "disables the move entry when it is the only row" do
      render_inline(described_class.new(work_package:, allocations: [],
                                        project:, resource_planner: planner, view: manual_view,
                                        first: true, last: true))

      expect(page).to have_css(".ActionListItem--disabled", text: "Move", visible: :all)
      %w[top up down bottom].each do |direction|
        expect(page).to have_no_css("form[action='#{move_path(manual_view, direction:)}']", visible: :all)
      end
    end
  end
end
