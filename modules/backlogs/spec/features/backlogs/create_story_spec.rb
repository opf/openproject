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

describe 'Backlogs', js: true do
  let(:story_type) do
    FactoryBot.create(:type_feature)
  end
  let(:story_type2) do
    type = FactoryBot.create(:type)

    project.types << type

    type
  end
  let(:inactive_story_type) do
    FactoryBot.create(:type)
  end

  let(:task_type) do
    type = FactoryBot.create(:type_task)
    project.types << type

    type
  end

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i(add_work_packages
                                                  view_master_backlog
                                                  view_work_packages
                                                  assign_versions)
  end
  let(:project) { FactoryBot.create :project }

  let(:backlog_version) { FactoryBot.create(:version, project: project) }

  let!(:existing_story1) do
    FactoryBot.create(:work_package,
                      type: story_type,
                      project: project,
                      status: default_status,
                      priority: default_priority,
                      position: 1,
                      story_points: 3,
                      version: backlog_version )
  end
  let!(:existing_story2) do
    FactoryBot.create(:work_package,
                      type: story_type,
                      project: project,
                      status: default_status,
                      priority: default_priority,
                      position: 2,
                      story_points: 4,
                      version: backlog_version)
  end
  let!(:default_status) do
    FactoryBot.create(:default_status)
  end
  let!(:default_priority) do
    FactoryBot.create(:default_priority)
  end

  before do
    login_as(user)

    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return('story_types' => [story_type.id.to_s,
                                          story_type2.id.to_s,
                                          inactive_story_type.id.to_s],
                        'task_type' => task_type.id.to_s)
  end

  it 'allows creating a new story' do
    visit backlogs_project_backlogs_path(project)

    within("#backlog_#{backlog_version.id}", wait: 10) do
      menu = find('.menu')
      menu.click
      click_link 'New Story'
      fill_in 'subject', with: "The new story"
      fill_in 'story points', with: "5"

      # inactive types should not be selectable
      # but the user can choose from the active types
      expect(page)
        .not_to have_selector('option', text: inactive_story_type.name)

      select story_type2.name, from: 'type'

      # saving the new story
      find(:css, 'input[name=subject]').native.send_key :return

      # velocity should be summed up immediately
      expect(page)
        .to have_selector('.velocity', text: "12")

      # this will ensure that the page refresh is through before we check the order
      menu.click
      click_link 'New Story'
      fill_in 'subject', with: "Another story"
    end

    # the order is kept even after a page refresh -> it is persisted in the db
    page.driver.refresh

    expect(page)
      .not_to have_content 'Another story'

    expect(page)
      .to have_selector '.story:nth-of-type(1)', text: 'The new story'
    expect(page)
      .to have_selector '.story:nth-of-type(2)', text: existing_story1.subject
    expect(page)
      .to have_selector '.story:nth-of-type(3)', text: existing_story2.subject

    # created with the selected type
    expect(page)
      .to have_selector '.story:nth-of-type(1) .type_id', text: story_type2.name
  end
end
