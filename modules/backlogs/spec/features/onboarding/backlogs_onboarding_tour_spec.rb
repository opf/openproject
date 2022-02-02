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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'backlogs onboarding tour', js: true do
  let(:next_button) { find('.enjoyhint_next_btn') }
  let(:user) { create :admin }
  let(:demo_project) do
    create :project,
                      name: 'Demo project',
                      identifier: 'demo-project',
                      public: true,
                      enabled_module_names: %w[work_package_tracking wiki]
  end
  let(:project) do
    create :project,
                      name: 'Scrum project',
                      identifier: 'your-scrum-project',
                      public: true,
                      enabled_module_names: %w[work_package_tracking wiki backlogs]
  end
  let(:sprint) { create(:version, project: project, name: 'Sprint 1') }
  let(:status) { create(:default_status) }
  let(:priority) { create(:default_priority) }

  let(:impediment) do
    build(:impediment, author: user,
                     version: sprint,
                     assigned_to: user,
                     project: project,
                     type: type_task,
                     status: status)
  end

  let(:story_type) { create(:type_feature) }
  let(:task_type) do
    type = create(:type_task)
    project.types << type

    type
  end

  let!(:existing_story) do
    create(:work_package,
                      type: story_type,
                      project: project,
                      status: status,
                      priority: priority,
                      position: 1,
                      story_points: 3,
                      version: sprint)
  end

  before do
    allow(Setting).to receive(:demo_projects_available).and_return(true)
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return('story_types' => [story_type.id.to_s],
                                                                       'task_type' => task_type.id.to_s)
  end

  after do
    # Clear session to avoid that the onboarding tour starts
    page.execute_script("window.sessionStorage.clear();")
  end

  context 'with a new user who is allowed to see the backlogs plugin' do
    before do
      login_as user
    end

    it 'I see a part of the onboarding tour in the backlogs section' do
      # Set the tour parameter so that we can start on the overview page
      visit "/projects/#{project.identifier}?start_scrum_onboarding_tour=true"
      expect(page).to have_text sanitize_string(I18n.t('js.onboarding.steps.backlogs.overview')), normalize_ws: true

      next_button.click
      text = sanitize_string(I18n.t('js.onboarding.steps.backlogs.sprints'))
      expect(page).to have_text Loofah.fragment(text).text(encode_special_chars: false), normalize_ws: true

      next_button.click
      expect(page).to have_text sanitize_string(I18n.t('js.onboarding.steps.backlogs.task_board_arrow')), normalize_ws: true

      next_button.click
      expect(page).to have_selector('.backlog .items', visible: true)
      expect(page).to have_text sanitize_string(I18n.t('js.onboarding.steps.backlogs.task_board_select')), normalize_ws: true

      next_button.click
      expect(page)
        .to have_current_path backlogs_project_sprint_taskboard_path(project.identifier, sprint.id)
      expect(page).to have_text sanitize_string(I18n.t('js.onboarding.steps.backlogs.task_board')), normalize_ws: true

      next_button.click
      expect(page)
        .to have_text sanitize_string(I18n.t('js.onboarding.steps.wp.toggler')), normalize_ws: true

      next_button.click
      expect(page).to have_current_path project_work_packages_path(project.identifier)
    end
  end

  context 'with a new user who is not allowed to see the backlogs plugin' do
    # necessary to be able to see public projects
    let(:non_member_role) { create :non_member, permissions: [:view_work_packages] }
    let(:non_member_user) { create :user }

    before do
      non_member_role
      login_as non_member_user
    end

    it 'skips the backlogs tour and continues directly with the WP tour' do
      # Set the tour parameter so that we can start on the overview page
      visit "/projects/#{project.identifier}?start_scrum_onboarding_tour=true"
      expect(page)
        .to have_text sanitize_string(I18n.t('js.onboarding.steps.wp.toggler')), normalize_ws: true

      next_button.click
      expect(page).to have_current_path project_work_packages_path(project.identifier)
    end
  end
end
