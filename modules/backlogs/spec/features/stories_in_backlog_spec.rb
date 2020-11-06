#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
                      types: [story, task],
                      enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:story) { FactoryBot.create(:type_feature) }
  let!(:task) { FactoryBot.create(:type_task) }
  let!(:priority) { FactoryBot.create(:default_priority) }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:other_status) { FactoryBot.create(:status) }
  let!(:workflows) do
    FactoryBot.create(:workflow,
                      old_status: status,
                      new_status: other_status,
                      role: role,
                      type_id: story.id)
    FactoryBot.create(:workflow,
                      old_status: status,
                      new_status: other_status,
                      role: role,
                      type_id: task.id)
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
                      version: sprint,
                      story_points: 10)
  end
  let!(:sprint_story2) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      version: sprint,
                      story_points: 20)
  end
  let!(:backlog_story1) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: story,
                      version: backlog)
  end
  let!(:sprint) do
    FactoryBot.create(:version,
                      project: project,
                      version_settings_attributes: [{ project: project, display: VersionSetting::DISPLAY_LEFT }])
  end
  let!(:backlog) do
    FactoryBot.create(:version,
                      project: project,
                      version_settings_attributes: [{ project: project, display: VersionSetting::DISPLAY_RIGHT }])
  end
  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    login_as current_user
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return('story_types' => [story.id.to_s],
                        'task_type' => task.id.to_s)
  end

  it 'displays stories which are editable' do
    backlogs_page.visit!

    # Velocity is calculated by summing up all story points in a sprint
    backlogs_page
      .expect_velocity(sprint_story1, 30)

    # Editing in a sprint
    backlogs_page
      .expect_story_in_sprint(sprint_story1, sprint)

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
      .expect_velocity(sprint_story1, 35)

    # Editing in the backlog
    backlogs_page
      .expect_story_in_sprint(backlog_story1, backlog)

    backlogs_page
      .edit_story(backlog_story1, subject: 'Altered backlog story1')

    backlog_story1.reload

    expect(backlog_story1.subject)
      .to eql 'Altered backlog story1'

    backlogs_page
      .expect_for_story(backlog_story1, subject: 'Altered backlog story1')
  end
end
