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
require_relative "shared_context"

RSpec.describe "Work package table context menu",
               :js,
               with_ee: %i[team_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with team planner full access"

  let!(:work_package) do
    create(:work_package,
           project:,
           assigned_to: user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end
  let(:menu) { Components::WorkPackages::ContextMenu.new }

  shared_let(:user) do
    create(:admin,
           member_with_permissions: { project => %w[
             view_work_packages edit_work_packages add_work_packages
             view_team_planner manage_team_planner
             save_queries manage_public_queries
             work_package_assigned
           ] })
  end

  before do
    login_as user
    team_planner.visit!

    team_planner.add_assignee user
    team_planner.within_lane(user) do
      team_planner.expect_event work_package
    end
  end

  it "provides a context menu" do
    menu.expect_closed
    menu.open_for(work_package, card_view: true)
    menu.expect_options "Open details view",
                        "Log time",
                        "Move to another project",
                        "Duplicate",
                        "Delete",
                        "Create new child"

    menu.choose "Open details view"
    Pages::SplitWorkPackage.new(work_package, project).expect_attributes Subject: work_package.subject
  end
end
