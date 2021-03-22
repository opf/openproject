#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative '../support/pages/backlogs'

describe 'Stories in backlog',
         type: :feature,
         js: true do
  let!(:project) do
    FactoryBot.create(:project,
                      types: [story, task, other_story],
                      enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:story) { FactoryBot.create(:type_feature) }
  let!(:other_story) { FactoryBot.create(:type) }
  let!(:task) { FactoryBot.create(:type_task) }
  let!(:priority) { FactoryBot.create(:default_priority) }
  let!(:default_status) { FactoryBot.create(:status, is_default: true) }
  let!(:other_status) { FactoryBot.create(:status) }
  let!(:workflows) do
    FactoryBot.create(:workflow,
                      old_status: default_status,
                      new_status: other_status,
                      role: role,
                      type_id: story.id)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i(view_master_backlog
                                      add_work_packages
                                      view_work_packages
                                      edit_work_packages
                                      manage_subtasks
                                      assign_versions))
  end
  let!(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:sprint_story1) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      status: default_status,
                      version: sprint,
                      position: 1,
                      story_points: 10)
  end
  let!(:sprint_story1_task) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: task,
                      status: default_status,
                      version: sprint)
  end
  let!(:sprint_story2_parent) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: FactoryBot.create(:type),
                      status: default_status,
                      version: sprint)
  end
  let!(:sprint_story2) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      status: default_status,
                      version: sprint,
                      position: 2,
                      story_points: 20)
  end
  let!(:backlog_story1) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      status: default_status,
                      version: backlog)
  end
  let!(:sprint) do
    FactoryBot.create(:version,
                      project: project,
                      start_date: Date.today - 10.days,
                      effective_date: Date.today + 10.days,
                      version_settings_attributes: [{ project: project, display: VersionSetting::DISPLAY_LEFT }])
  end
  let!(:backlog) do
    FactoryBot.create(:version,
                      project: project,
                      version_settings_attributes: [{ project: project, display: VersionSetting::DISPLAY_RIGHT }])
  end
  let!(:other_project) do
    FactoryBot.create(:project).tap do |p|
      FactoryBot.create(:member,
                        principal: current_user,
                        project: p,
                        roles: [role])
    end
  end
  let!(:sprint_story_in_other_project) do
    FactoryBot.create(:work_package,
                      project: other_project,
                      type: story,
                      status: default_status,
                      version: sprint,
                      story_points: 10)
  end
  let!(:export_card_configurations) do
    ExportCardConfiguration.create!(name: 'Default',
                                    per_page: 1,
                                    page_size: 'A4',
                                    orientation: 'landscape',
                                    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false")
  end
  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return('story_types' => [story.id.to_s, other_story.id.to_s],
                        'task_type' => task.id.to_s)
  end

  it 'displays stories which are editable' do
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
      .click_in_backlog_menu(sprint, 'New Story')

    SeleniumHubWaiter.wait
    backlogs_page
      .edit_new_story(subject: 'New story',
                      story_points: 10)

    new_story = WorkPackage.find_by(subject: 'New story')

    backlogs_page
      .expect_story_in_sprint(new_story, sprint)

    # All positions will be unique in the sprint
    expect(Story.where(version: sprint, type: story, project: project).pluck(:position))
      .to match_array([1, 2, 3])

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story1, sprint_story2)

    # Creating the story will update the velocity
    backlogs_page
      .expect_velocity(sprint, 40)

    # Editing in a sprint

    SeleniumHubWaiter.wait
    backlogs_page
      .edit_story(sprint_story1,
                  subject: 'Altered story1',
                  story_points: 15)

    sprint_story1.reload

    expect(sprint_story1.subject)
      .to eql 'Altered story1'

    backlogs_page
      .expect_for_story(sprint_story1, subject: 'Altered story1')

    # Updating the story_points of a story will update the velocity of the sprint
    backlogs_page
      .expect_velocity(sprint, 45)

    SeleniumHubWaiter.wait
    # Moving a story to top
    backlogs_page
      .drag_in_sprint(sprint_story1, new_story)

    backlogs_page
      .expect_stories_in_order(sprint, sprint_story1, new_story, sprint_story2)

    expect(Story.where(version: sprint, type: story, project: project).pluck(:position))
      .to match_array([1, 2, 3])

    # Moving a story to bottom
    backlogs_page
      .drag_in_sprint(sprint_story1, sprint_story2, before: false)

    sleep(0.5)

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story2, sprint_story1)

    expect(Story.where(version: sprint, type: story, project: project).pluck(:position))
      .to match_array([1, 2, 3])

    # Moving a story to from the backlog to the sprint (3nd position)

    SeleniumHubWaiter.wait
    backlogs_page
      .drag_in_sprint(backlog_story1, sprint_story2, before: false)

    backlogs_page
      .expect_stories_in_order(sprint, new_story, sprint_story2, backlog_story1, sprint_story1)

    expect(Story.where(version: sprint, type: story, project: project).pluck(:position))
      .to match_array([1, 2, 3, 4])

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
                                           subject: 'Altered backlog story1',
                                           status: other_status.name)
    backlogs_page
      .save_story_from_edit_mode(backlog_story1)

    backlog_story1.reload

    expect(backlog_story1.subject)
      .to eql 'Altered backlog story1'

    expect(backlog_story1.status)
      .to eql other_status

    backlogs_page
      .expect_for_story(backlog_story1,
                        subject: 'Altered backlog story1',
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
                        subject: 'Altered backlog story1',
                        status: default_status.name,
                        type: other_story.name)

    # The pdf export is reachable via the menu
    SeleniumHubWaiter.wait
    backlogs_page
      .click_in_backlog_menu(sprint, 'Export')
    # Will download something that is currently not speced

    # Clicking would lead to having the burndown chart opened in another tab
    # which seems hard to test with selenium.
    backlogs_page
      .expect_in_backlog_menu(sprint, 'Burndown Chart')

    # One can switch to the work package page by clicking on the id
    # Clicking on it will open the wp in another tab which seems to trip up selenium.
    backlogs_page
      .expect_story_link_to_wp_page(sprint_story1)

    # Go to the index page of work packages within that sprint via the menu
    backlogs_page
      .click_in_backlog_menu(sprint, 'Stories/Tasks')

    wp_table = Pages::WorkPackagesTable.new(project)

    wp_table
      .expect_work_package_listed(new_story, sprint_story2, backlog_story1, sprint_story1)
  end
end
