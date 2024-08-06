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

RSpec.describe "Backlogs in backlog view", :js,
               with_cuprite: false do
  let!(:project) do
    create(:project,
           types: [story, task],
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
                           manage_versions
                           update_sprints
                           assign_versions))
  end
  let!(:current_user) do
    create(:user,
           member_with_roles: { project => role })
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
    create(:project)
  end
  let!(:other_project_sprint) do
    create(:version,
           project: other_project,
           sharing: "system",
           start_date: Date.today - 10.days,
           effective_date: Date.today + 10.days)
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
  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return("story_types" => [story.id.to_s],
                        "task_type" => task.id.to_s)
  end

  it "displays stories which are editable" do
    backlogs_page.visit!

    backlogs_page
      .expect_sprint(sprint)

    # Shared versions are also displayed as a sprint.
    # Without version settings, it is displayed as a sprint
    backlogs_page
      .expect_sprint(other_project_sprint)

    backlogs_page
      .expect_backlog(backlog)

    # Versions can be folded
    backlogs_page
      .expect_story_in_sprint(sprint_story1, sprint)

    backlogs_page
      .fold_backlog(sprint)

    backlogs_page
      .expect_story_not_in_sprint(sprint_story1, sprint)

    # The backlogs can be folded by default
    visit my_settings_path

    check "Show versions folded"

    click_button "Save"

    backlogs_page.visit!

    backlogs_page
      .expect_story_not_in_sprint(sprint_story1, sprint)

    backlogs_page
      .fold_backlog(sprint)

    backlogs_page
      .expect_story_in_sprint(sprint_story1, sprint)

    # Alter the attributes of the sprint
    sleep(0.5)
    backlogs_page
      .edit_backlog(sprint, name: "")

    backlogs_page
      .expect_and_dismiss_error("Name can't be blank.")

    sleep(0.2)

    backlogs_page
      .edit_backlog(sprint,
                    name: "New sprint name",
                    start_date: Date.today + 5.days,
                    effective_date: Date.today + 20.days)

    sleep(0.5)

    sprint.reload

    expect(sprint.name)
      .to eql "New sprint name"

    expect(sprint.start_date)
      .to eql Date.today + 5.days

    expect(sprint.effective_date)
      .to eql Date.today + 20.days

    # Alter displaying a sprints as a backlog

    backlogs_page
      .click_in_backlog_menu(sprint, "Properties")

    select "right", from: "Column in backlog"

    click_button "Save"

    backlogs_page
      .expect_and_dismiss_toaster(message: "Successful update.")

    backlogs_page
      .expect_backlog(sprint)

    # The others are unchanged
    backlogs_page
      .expect_backlog(backlog)

    backlogs_page
      .expect_sprint(other_project_sprint)

    # Alter displaying a backlog as a sprint
    backlogs_page
      .click_in_backlog_menu(backlog, "Properties")

    select "left", from: "Column in backlog"

    click_button "Save"

    backlogs_page
      .expect_and_dismiss_toaster(message: "Successful update.")

    # Now works as a sprint instead of a backlog
    backlogs_page
      .expect_sprint(backlog)

    # The others are unchanged
    backlogs_page
      .expect_backlog(sprint)

    backlogs_page
      .expect_sprint(other_project_sprint)

    # Alter displaying a version not at all
    backlogs_page
      .click_in_backlog_menu(backlog, "Properties")

    select "none", from: "Column in backlog"

    click_button "Save"

    backlogs_page
      .expect_and_dismiss_toaster(message: "Successful update.")

    # the disabled backlog/sprint is no longer visible
    expect(page)
      .to have_no_content(backlog.name)

    # The others are unchanged
    backlogs_page
      .expect_backlog(sprint)

    backlogs_page
      .expect_sprint(other_project_sprint)

    # Inherited versions can also be modified
    backlogs_page
      .click_in_backlog_menu(other_project_sprint, "Properties")

    select "none", from: "Column in backlog"

    click_button "Save"

    backlogs_page
      .expect_and_dismiss_toaster(message: "Successful update.")

    # the disabled backlog/sprint is no longer visible
    expect(page)
      .to have_no_content(other_project_sprint.name)

    # The others are unchanged
    backlogs_page
      .expect_backlog(sprint)

    expect(page)
      .to have_no_content(backlog.name)
  end
end
