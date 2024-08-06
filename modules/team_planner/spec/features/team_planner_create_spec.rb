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
require_relative "shared_context"

RSpec.describe "Team planner create new work package", :js, with_ee: %i[team_planner_view] do
  include_context "with team planner full access"

  let(:type_task) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }

  before do
    project.types << type_task
  end

  shared_examples "can create a new work package" do
    it "creates a new work package for the given user" do
      start_of_week = Time.zone.today.beginning_of_week(:sunday)
      team_planner.expect_assignee(user)
      split_create = team_planner.add_item "/api/v3/users/#{user.id}",
                                           start_of_week.iso8601,
                                           start_of_week.iso8601

      subject = split_create.edit_field(:subject)
      subject.set_value "Newly planned task"

      split_create.save!

      split_create.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))

      split_create.expect_attributes(
        combinedDate: start_of_week.strftime("%m/%d/%Y"),
        assignee: user.name
      )

      wp = WorkPackage.last
      expect(wp.subject).to eq "Newly planned task"
      expect(wp.start_date).to eq start_of_week
      expect(wp.due_date).to eq start_of_week

      team_planner.within_lane(user) do
        team_planner.expect_event wp
      end
    end
  end

  context "with a single user" do
    before do
      team_planner.visit!

      team_planner.expect_assignee(user, present: false)

      team_planner.add_assignee user.name
    end

    it_behaves_like "can create a new work package"
  end

  context "with multiple users added" do
    let!(:other_user) do
      create(:user,
             firstname: "Other",
             lastname: "User",
             member_with_permissions: { project => %w[
               view_work_packages edit_work_packages add_work_packages
               view_team_planner manage_team_planner
               save_queries manage_public_queries
               work_package_assigned
             ] })
    end

    let!(:third_user) do
      create(:user,
             firstname: "Other",
             lastname: "User",
             member_with_permissions: { project => %w[
               view_work_packages edit_work_packages add_work_packages
               view_team_planner manage_team_planner
               save_queries manage_public_queries
               work_package_assigned
             ] })
    end

    before do
      team_planner.visit!

      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user, present: false)
      team_planner.expect_assignee(third_user, present: false)

      team_planner.add_assignee other_user.name
      team_planner.add_assignee third_user.name
      team_planner.add_assignee user.name
    end

    it_behaves_like "can create a new work package"
  end
end
