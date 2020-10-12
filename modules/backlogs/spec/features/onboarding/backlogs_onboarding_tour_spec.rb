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

describe 'backlogs onboarding tour', js: true do
  let(:next_button) { find('.enjoyhint_next_btn') }
  let(:user) { FactoryBot.create :admin }
  let(:demo_project) do
    FactoryBot.create :project,
                      name: 'Demo project',
                      identifier: 'demo-project',
                      public: true,
                      enabled_module_names: %w[work_package_tracking wiki]
  end
  let(:project) do
    FactoryBot.create :project,
                      name: 'Scrum project',
                      identifier: 'your-scrum-project',
                      public: true,
                      enabled_module_names: %w[work_package_tracking wiki backlogs]
  end
  let(:sprint) { FactoryBot.create(:version, project: project, name: 'Sprint 1') }
  let(:status) { FactoryBot.create(:default_status) }
  let(:priority) { FactoryBot.create(:default_priority) }

  let(:impediment) do
    FactoryBot.build(:impediment, author: user,
                     version: sprint,
                     assigned_to: user,
                     project: project,
                     type: type_task,
                     status: status)
  end

  let(:story_type) { FactoryBot.create(:type_feature) }
  let(:task_type) do
    type = FactoryBot.create(:type_task)
    project.types << type

    type
  end

  let!(:existing_story) do
    FactoryBot.create(:work_package,
                      type: story_type,
                      project: project,
                      status: status,
                      priority: priority,
                      position: 1,
                      story_points: 3,
                      version: sprint )
  end

  before do
    login_as user
    allow(Setting).to receive(:demo_projects_available).and_return(true)
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return('story_types' => [story_type.id.to_s],
                                                                       'task_type' => task_type.id.to_s)
  end

  after do
    # Clear session to avoid that the onboarding tour starts
    page.execute_script("window.sessionStorage.clear();")
  end

  context 'as a new user' do
    it 'I see a part of the onboarding tour in the backlogs section' do
      # Set the tour parameter so that we can start on the overview page
      visit "/projects/#{project.identifier}/backlogs/?start_scrum_onboarding_tour=true"
      expect(page).to have_text 'Manage your work in the Backlogs view.'

      next_button.click
      expect(page).to have_text 'To see your Task board, open the Sprint drop-down...'

      next_button.click
      expect(page).to have_selector('.backlog .items', visible: true)
      expect(page).to have_text '... and select the Task board entry.'

      next_button.click
      expect(page)
        .to have_current_path backlogs_project_sprint_taskboard_path(project.identifier, sprint.id)
      expect(page).to have_text 'The Task board visualizes the progress for this sprint.'

      next_button.click
      expect(page)
        .to have_text "Now let's have a look at the Work package section, which gives you a more detailed view of your work."

      next_button.click
      expect(page).to have_current_path project_work_packages_path(project.identifier)
    end
  end
end
