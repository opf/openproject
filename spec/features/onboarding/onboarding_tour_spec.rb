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

describe 'onboarding tour for new users', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project, name: 'My Project', identifier: 'project1', is_public: true, enabled_module_names: %w[work_package_tracking] }
  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }

  context 'as a new user' do
    before do
      login_as user
      visit home_path first_time_user: true
    end

    it 'I can select a language' do
      expect(page).to have_text 'Please select your language for OpenProject'

      select 'Deutsch', :from => 'user_language'
      click_button 'Save'

      expect(page).to have_text 'Projekt auswählen'
    end

    context 'the tutorial starts' do
      before do
        select 'English', :from => 'user_language'
        click_button 'Save'
      end

      it 'directly after the language selection' do
        # The tutorial appears
        expect(page).to have_text 'Welcome to our short introduction tour to show you the important features in OpenProject'
        expect(page).to have_selector '.enjoyhint_next_btn:not(.enjoyhint_hide)'
        expect(page).to have_selector '.enjoyhint_skip_btn:not(.enjoyhint_hide)'
      end

      it 'and I skip the tutorial' do
        find('.enjoyhint_skip_btn').click

        # The tutorial disappears
        expect(page).not_to have_text 'Welcome to our short introduction tour to show you the important features in OpenProject'
        expect(page).not_to have_selector '.enjoyhint_next_btn'

        page.driver.browser.navigate.refresh

        # The tutorial did not start again
        expect(page).not_to have_text 'Welcome to our short introduction tour to show you the important features in OpenProject'
        expect(page).not_to have_selector '.enjoyhint_next_btn'
      end

      it 'and I continue the tutorial' do
        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'Please select one of the projects with useful demo data to get started.'

        click_link 'My Project'
        expect(page).to have_current_path project_path('project1')
        expect(page).to have_text 'This is the project’s Overview page.'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'From the Project menu you can access all modules within a project.'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'In the Project settings you can configure your project’s modules.'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'Invite new Members to join your project.'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'Here is the Work package section'

        find('#main-menu-work-packages-wrapper .toggler').click
        expect(page).to have_text  "Let's have a look at all open Work packages"

        find('.wp-query-menu--item-link', text: 'All open').click
        expect(page).to have_current_path project_work_packages_path('project1')
        expect(page).not_to have_selector('.loading-indicator')
        expect(page).to have_text  'This is the Work package list.'

        find('.wp-table--row').double_click
        expect(page).to have_current_path project_work_package_path(project, wp_1.id, 'activity')
        expect(page).to have_text  'Within the Work package details you find all relevant information'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'With the arrow you can navigate back to the work package list.'

        find('.work-packages-list-view-button').click
        expect(page).to have_text 'The Create button will add a new work package to your project'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'On the top, you can activate the Gantt chart.'

        find('#work-packages-timeline-toggle-button').click
        expect(page).to have_text 'Here you can create and visualize a project plan and share it with your team.'

        find('.enjoyhint_next_btn').click
        expect(page).to have_text 'In the Help menu you will find a user guide and additional help resources.'

        find('.enjoyhint_next_btn').click
        expect(page).not_to have_selector '.enjoy_hint_label'
      end
    end
  end
end


