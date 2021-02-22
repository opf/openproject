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
require_relative '../support/pages/taskboard'

describe 'Tasks on taskboard',
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
                      type_id: task.id)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i(view_taskboards
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
  let!(:story1) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      status: default_status,
                      version: sprint,
                      position: 1,
                      story_points: 10)
  end
  let!(:story1_task) do
    FactoryBot.create(:work_package,
                      project: project,
                      parent: story1,
                      type: task,
                      status: default_status,
                      version: sprint)
  end
  let!(:story1_task_subtask) do
    FactoryBot.create(:work_package,
                      project: project,
                      parent: story1_task,
                      type: task,
                      status: default_status,
                      version: sprint)
  end
  let!(:other_work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: FactoryBot.create(:type),
                      status: default_status,
                      version: sprint)
  end
  let!(:other_work_package_subtask) do
    FactoryBot.create(:work_package,
                      project: project,
                      parent: other_work_package,
                      type: task,
                      status: default_status,
                      version: sprint)
  end
  let!(:story2) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      status: default_status,
                      version: sprint,
                      position: 2,
                      story_points: 20)
  end
  let!(:sprint) do
    FactoryBot.create(:version,
                      project: project,
                      start_date: Date.today - 10.days,
                      effective_date: Date.today + 10.days,
                      version_settings_attributes: [{ project: project, display: VersionSetting::DISPLAY_LEFT }])
  end
  let!(:other_project) do
    FactoryBot.create(:project).tap do |p|
      FactoryBot.create(:member,
                        principal: current_user,
                        project: p,
                        roles: [role])
    end
  end
  let!(:story_in_other_project) do
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
  let(:taskboard_page) { Pages::Taskboard.new(project, sprint) }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return('story_types' => [story.id.to_s, other_story.id.to_s],
                        'task_type' => task.id.to_s)
  end

  it 'displays stories which are editable' do
    taskboard_page.visit!

    # All stories of the sprint are visible
    taskboard_page
      .expect_story(story1)

    taskboard_page
      .expect_story(story2)

    # All tasks of the sprint are visible
    taskboard_page
      .expect_task(story1_task)

    # Other work packages also assigned to the sprint are not visible
    taskboard_page
      .expect_work_package_not_visible(other_work_package)

    # Tasks that have a non story as their parent are not visible
    taskboard_page
      .expect_work_package_not_visible(other_work_package_subtask)

    # Tasks that have a task and not a story as their parent are not visible
    taskboard_page
      .expect_work_package_not_visible(story1_task_subtask)

    # The task is in the first status column belonging to its parent story
    taskboard_page
      .expect_task_in_story_column(story1_task, story1, 1)

    # Adding a task will have it added to the same sprint and belonging to the story
    taskboard_page
      .add_task(story1,
                subject: "Added task",
                assignee: current_user.name,
                remaining_hours: 7)

    added_task = WorkPackage.find_by(subject: "Added task")

    expect(added_task.version)
      .to eql sprint

    expect(added_task.parent)
      .to eql story1

    # Added task will also be displayed
    taskboard_page
      .expect_task_in_story_column(added_task, story1, 1)

    # Updating a task
    taskboard_page
      .update_task(story1_task,
                   subject: "Updated task",
                   assignee: current_user.name)

    story1_task.reload

    expect(story1_task.subject)
      .to eql "Updated task"

    # Dragging a task within the same column (switching order)
    taskboard_page
      .drag_to_task(story1_task, added_task, :before)

    taskboard_page
      .expect_task_in_story_column(added_task, story1, 1)

    taskboard_page
      .expect_task_in_story_column(story1_task, story1, 1)

    sleep(0.5)

    expect(added_task.reload.higher_item.id)
      .to eql story1_task.id

    # Dragging a task to the next column (switching status)
    taskboard_page
      .drag_to_column(story1_task, story1, 2)

    taskboard_page
      .expect_task_in_story_column(story1_task, story1, 2)

    sleep(0.5)

    expect(story1_task.reload.status)
      .to eql other_status

    # There is a button to the burndown chart
    expect(page)
      .to have_selector("a[href='#{backlogs_project_sprint_burndown_chart_path(project, sprint)}']",
                        text: 'Burndown Chart')

    # Tasks can get a color per assigned user
    visit my_settings_path

    fill_in 'Task color', with: '#FBC4B3'

    click_button 'Save'

    taskboard_page.visit!

    taskboard_page
      .expect_color_for_task('#FBC4B3', story1_task)
  end
end
