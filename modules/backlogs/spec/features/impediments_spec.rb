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

RSpec.describe "Impediments on taskboard", :js,
               with_cuprite: false do
  let!(:project) do
    create(:project,
           types: [story, task],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:story) { create(:type_feature) }
  let!(:task) { create(:type_task) }
  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:status, is_default: true) }
  let!(:other_status) { create(:status) }
  let!(:workflows) do
    create(:workflow,
           old_status: status,
           new_status: other_status,
           role:,
           type_id: story.id)
    create(:workflow,
           old_status: status,
           new_status: other_status,
           role:,
           type_id: task.id)
  end
  let(:role) do
    create(:project_role,
           permissions: %i(view_taskboards
                           add_work_packages
                           view_work_packages
                           edit_work_packages
                           manage_subtasks
                           assign_versions
                           work_package_assigned))
  end
  let!(:current_user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let!(:task1) do
    create(:work_package,
           status:,
           project:,
           type: task,
           version: sprint,
           parent: story1)
  end
  let!(:story1) do
    create(:work_package,
           project:,
           type: story,
           version: sprint)
  end
  let!(:other_task) do
    create(:work_package,
           project:,
           type: task,
           version: sprint,
           parent: other_story)
  end
  let!(:other_story) do
    create(:work_package,
           project:,
           type: story,
           version: other_sprint)
  end
  let!(:sprint) do
    create(:version, project:)
  end
  let!(:other_sprint) do
    create(:version, project:)
  end

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return("story_types" => [story.id.to_s],
                  "task_type" => task.id.to_s)
  end

  it "allows creating and updating impediments" do
    visit backlogs_project_sprint_taskboard_path(project, sprint)

    find("#impediments .add_new").click

    fill_in "subject", with: "New impediment"
    fill_in "blocks_ids", with: task1.id
    select current_user.name, from: "assigned_to_id"
    click_on "OK"

    # Saves successfully
    expect(page)
      .to have_css("div.impediment", text: "New impediment")
    expect(page)
      .to have_no_css("div.impediment.error", text: "New impediment")

    # Attempt to create a new impediment with the id of a story from another sprint
    find("#impediments .add_new").click

    fill_in "subject", with: "Other sprint impediment"
    fill_in "blocks_ids", with: other_story.id
    click_on "OK"

    # Saves unsuccessfully
    expect(page)
      .to have_css("div.impediment", text: "Other sprint impediment")
    expect(page)
      .to have_css("div.impediment.error", text: "Other sprint impediment")
    expect(page)
      .to have_css("#msgBox",
                   text: "IDs of blocked work packages can only contain IDs of work packages in the current sprint.")

    click_on "OK"

    # Attempt to create a new impediment with a non existing id
    find("#impediments .add_new").click

    fill_in "subject", with: "Invalid id impediment"
    fill_in "blocks_ids", with: "0"
    click_on "OK"

    # Saves unsuccessfully
    expect(page)
      .to have_css("div.impediment", text: "Invalid id impediment")
    expect(page)
      .to have_css("div.impediment.error", text: "Invalid id impediment")
    expect(page)
      .to have_css("#msgBox",
                   text: "IDs of blocked work packages can only contain IDs of work packages in the current sprint.")
    click_on "OK"

    # Attempt to create a new impediment without specifying the blocked story/task
    find("#impediments .add_new").click

    fill_in "subject", with: "Unblocking impediment"
    click_on "OK"

    # Saves unsuccessfully
    expect(page)
      .to have_css("div.impediment", text: "Unblocking impediment")
    expect(page)
      .to have_css("div.impediment.error", text: "Unblocking impediment")
    expect(page)
      .to have_css("#msgBox", text: "IDs of blocked work packages must contain the ID of at least one ticket")
    click_on "OK"

    # Updating an impediment
    find("#impediments .subject", text: "New impediment").click

    fill_in "subject", with: "Updated impediment"
    fill_in "blocks_ids", with: story.id
    click_on "OK"

    # Saves successfully
    expect(page)
      .to have_css("div.impediment", text: "Updated impediment")
    expect(page)
      .to have_no_css("div.impediment.error", text: "Updated impediment")
  end
end
