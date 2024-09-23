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
require_relative "../support/pages/backlogs"

RSpec.describe "Stories in backlog", :js,
               with_cuprite: false do
  let!(:project) do
    create(:project,
           types: [story, task, other_story],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:story) { create(:type_feature) }
  let!(:other_story) { create(:type) }
  let!(:task) { create(:type_task) }
  let!(:priority) { create(:default_priority) }
  let!(:default_status) { create(:status, is_default: true) }
  let!(:other_status) { create(:status) }
  let!(:workflows) do
    create(:workflow,
           old_status: default_status,
           new_status: other_status,
           role:,
           type_id: story.id)
  end
  let(:role) do
    create(:project_role,
           permissions: %i(view_master_backlog
                           add_work_packages
                           view_work_packages
                           edit_work_packages
                           manage_subtasks
                           assign_versions))
  end
  let!(:current_user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let!(:sprint_story1) do
    create(:work_package,
           project:,
           type: story,
           status: default_status,
           version: sprint,
           position: 1,
           story_points: 10)
  end
  let!(:sprint_story1_task) do
    create(:work_package,
           project:,
           type: task,
           status: default_status,
           version: sprint)
  end
  let!(:sprint_story2_parent) do
    create(:work_package,
           project:,
           type: create(:type),
           status: default_status,
           version: sprint)
  end
  let!(:sprint_story2) do
    create(:work_package,
           project:,
           type: story,
           status: default_status,
           version: sprint,
           position: 2,
           story_points: 20)
  end
  let!(:backlog_story1) do
    create(:work_package,
           project:,
           type: story,
           status: default_status,
           version: backlog)
  end
  let!(:sprint) do
    create(:version,
           project:,
           start_date: Date.today - 10.days,
           effective_date: Date.today + 10.days,
           version_settings_attributes: [{ project:, display: VersionSetting::DISPLAY_LEFT }])
  end
  let!(:backlog) do
    create(:version,
           project:,
           version_settings_attributes: [{ project:, display: VersionSetting::DISPLAY_RIGHT }])
  end
  let!(:other_project) do
    create(:project).tap do |p|
      create(:member,
             principal: current_user,
             project: p,
             roles: [role])
    end
  end
  let!(:sprint_story_in_other_project) do
    create(:work_package,
           project: other_project,
           type: story,
           status: default_status,
           version: sprint,
           story_points: 10)
  end
  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return("story_types" => [story.id.to_s, other_story.id.to_s],
                        "task_type" => task.id.to_s)
  end

  it "displays stories which are editable" do
    backlogs_page.visit!

    # All stories are visible in their sprint/backlog
    # but non stories are not displayed
    backlogs_page
      .expect_story_in_sprint(sprint_story1, sprint)

    backlogs_page
      .expect_story_in_sprint(sprint_story2, sprint)

    backlogs_page
      .expect_story_in_sprint(backlog_story1, backlog)

    backlogs_page
      .expect_story_not_in_sprint(sprint_story2_parent, sprint)

    backlogs_page
      .expect_story_not_in_sprint(sprint_story1_task, sprint)

    backlogs_page
      .expect_story_not_in_sprint(sprint_story_in_other_project, sprint)

    backlogs_page
      .expect_stories_in_order(sprint, sprint_story1, sprint_story2)

    # Velocity is calculated by summing up all story points in a sprint
    backlogs_page
      .expect_velocity(sprint, 30)

    SeleniumHubWaiter.wait
    # Creating a story
    backlogs_page
      .click_in_backlog_menu(sprint, "New Story")

    SeleniumHubWaiter.wait
    backlogs_page
      .edit_new_story(subject: "New story",
                      story_points: 10)

    new_story = nil
    retry_block do
      new_story = WorkPackage.find_by(subject: "New story")
      raise "Expected story" unless new_story
    end

    backlogs_page
      .expect_story_in_sprint(new_story, sprint)

    # All positions will be unique in the sprint
    expect(Story.where(version: sprint, type: story, project:).pluck(:position))
      .to contain_exactly(1, 2, 3)

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story1, sprint_story2)

    # Creating the story will update the velocity
    backlogs_page
      .expect_velocity(sprint, 40)

    # Editing in a sprint

    SeleniumHubWaiter.wait
    backlogs_page
      .edit_story(sprint_story1,
                  subject: "Altered story1",
                  story_points: 15)

    retry_block do
      sprint_story1.reload
      raise "Expected story to be renamed" unless sprint_story1.subject == "Altered story1"
    end

    backlogs_page
      .expect_for_story(sprint_story1, subject: "Altered story1")

    # Updating the story_points of a story will update the velocity of the sprint
    backlogs_page
      .expect_velocity(sprint, 45)

    SeleniumHubWaiter.wait
    # Moving a story to top
    backlogs_page
      .drag_in_sprint(sprint_story1, new_story)

    backlogs_page
      .expect_stories_in_order(sprint, sprint_story1, new_story, sprint_story2)

    expect(Story.where(version: sprint, type: story, project:).pluck(:position))
      .to contain_exactly(1, 2, 3)

    # Moving a story to bottom
    backlogs_page
      .drag_in_sprint(sprint_story1, sprint_story2, before: false)

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story2, sprint_story1)

    expect(Story.where(version: sprint, type: story, project:).pluck(:position))
      .to contain_exactly(1, 2, 3)

    # Moving a story to from the backlog to the sprint (3rd position)

    SeleniumHubWaiter.wait
    backlogs_page
      .drag_in_sprint(backlog_story1, sprint_story2, before: false)

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story2, backlog_story1, sprint_story1)

    expect(Story.where(version: sprint, type: story, project:).pluck(:position))
      .to contain_exactly(1, 2, 3, 4)

    # Available statuses when editing

    backlogs_page
      .enter_edit_story_mode(backlog_story1)

    # The available statuses include those available by the workflow:
    # Current and every reachable one
    backlogs_page
      .expect_status_options(backlog_story1,
                             [default_status, other_status])

    SeleniumHubWaiter.wait
    backlogs_page
      .alter_attributes_in_edit_story_mode(backlog_story1,
                                           subject: "Altered backlog story1",
                                           status: other_status.name)
    backlogs_page
      .save_story_from_edit_mode(backlog_story1)

    retry_block do
      backlog_story1.reload
      raise "Expected story to be renamed" unless backlog_story1.subject == "Altered backlog story1"
    end

    expect(backlog_story1.status)
      .to eql other_status

    backlogs_page
      .expect_for_story(backlog_story1,
                        subject: "Altered backlog story1",
                        status: other_status.name)

    SeleniumHubWaiter.wait
    backlogs_page
      .enter_edit_story_mode(backlog_story1)

    # Since we switched to other status, only the current status and the next one is available now.
    backlogs_page
      .expect_status_options(backlog_story1,
                             [other_status])

    # Available statuses when editing and switching the type
    backlogs_page
      .alter_attributes_in_edit_story_mode(backlog_story1,
                                           type: other_story)
    # This will result in an error as the current status is not available
    backlogs_page
      .save_story_from_edit_mode(backlog_story1)

    backlogs_page
      .expect_for_story(backlog_story1,
                        subject: "Altered backlog story1",
                        status: default_status.name,
                        type: other_story.name)

    # Clicking would lead to having the burndown chart opened in another tab
    # which seems hard to test with selenium.
    backlogs_page
      .expect_in_backlog_menu(sprint, "Burndown Chart")

    # One can switch to the work package page by clicking on the id
    # Clicking on it will open the wp in another tab which seems to trip up selenium.
    backlogs_page
      .expect_story_link_to_wp_page(sprint_story1)

    # Go to the index page of work packages within that sprint via the menu
    backlogs_page
      .click_in_backlog_menu(sprint, "Stories/Tasks")

    wp_table = Pages::WorkPackagesTable.new(project)

    wp_table
      .expect_work_package_listed(new_story, sprint_story2, backlog_story1, sprint_story1)
  end
end
