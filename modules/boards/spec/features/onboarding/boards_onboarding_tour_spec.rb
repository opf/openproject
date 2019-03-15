#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'boards onboarding tour', js: true do
  let(:next_button) { find('.enjoyhint_next_btn') }
  let(:user) { FactoryBot.create :admin }
  let(:demo_project) { FactoryBot.create :project, name: 'Demo project', identifier: 'demo-project', is_public: true, enabled_module_names: %w[work_package_tracking] }
  let(:project) { FactoryBot.create :project, name: 'Scrum project', identifier: 'your-scrum-project', is_public: true, enabled_module_names: %w[work_package_tracking] }

  before do
    with_enterprise_token :board_view
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
    it 'I see the board onboarding tour in the demo project' do
      # Set the tour parameter so that we can start on the wp page
      visit "/projects/#{demo_project.identifier}/?start_onboarding_tour=true"

      step_through_onboarding_wp_tour

      next_button.click
      expect(page).to have_text 'Manage your work within an intuitive Boards view.'

      next_button.click
      expect(page).to have_text 'You can create multiple lists (columns) within one Board view, e.g. to create a KANBAN board.'

      next_button.click
      expect(page).to have_text 'Click the + will add a new card to the list within a Board.'

      next_button.click
      expect(page).to have_text 'Drag & Drop your cards within a list to re-order, or the another list. A double click will open the details view.'

      step_through_onboarding_main_menu_tour
    end


    it "I don't see the board onboarding tour in the scrum project" do
      # Set the tour parameter so that we can start on the wp page
      visit "/projects/#{project.identifier}/?start_onboarding_tour=true"

      step_through_onboarding_wp_tour
      step_through_onboarding_main_menu_tour
    end
  end
end


