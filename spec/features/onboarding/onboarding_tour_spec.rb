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

describe 'onboarding tour for new users', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project, name: 'Demo project', identifier: 'demo-project', public: true, enabled_module_names: %w[work_package_tracking wiki] }
  let(:scrum_project) {FactoryBot.create :project, name: 'Scrum project', identifier: 'your-scrum-project', public: true, enabled_module_names: %w[work_package_tracking] }
  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }
  let(:next_button) { find('.enjoyhint_next_btn') }

  context 'as a new user' do
    before do
      login_as user
      allow(Setting).to receive(:demo_projects_available).and_return(true)
      allow(Setting).to receive(:welcome_title).and_return('Hey ho!')
      allow(Setting).to receive(:welcome_on_homescreen?).and_return(true)
    end

    it 'I can select a language' do
      visit home_path first_time_user: true
      expect(page).to have_text 'Please select your language'

      select 'Deutsch', :from => 'user_language'
      click_button 'Save'

      expect(page).to have_text 'Projekt auswählen'
    end

    context 'the tutorial does not start' do
      before do
        allow(Setting).to receive(:welcome_text).and_return("<a> #{project.name} </a>")
        visit home_path first_time_user: true

        select 'English', :from => 'user_language'
        click_button 'Save'
      end

      it 'when the welcome block does not include the demo projects' do
        expect(page).not_to have_text 'Take a three minutes introduction tour to learn the most important features.'
        expect(page).not_to have_selector '.enjoyhint_next_btn'
      end
    end

    context 'the tutorial starts' do
      before do
        allow(Setting).to receive(:welcome_text).and_return("<a href=/projects/#{project.identifier}> #{project.name} </a><a href=/projects/#{scrum_project.identifier}> #{scrum_project.name} </a>")
        visit home_path first_time_user: true

        select 'English', :from => 'user_language'
        click_button 'Save'
      end

      after do
        # Clear session to avoid that the onboarding tour starts
        page.execute_script("window.sessionStorage.clear();")
      end

      it 'directly after the language selection' do
        # The tutorial appears
        expect(page).to have_text 'Take a three minutes introduction tour to learn the most important features.'
        expect(page).to have_selector '.enjoyhint_next_btn:not(.enjoyhint_hide)'
      end

      it 'and I skip the tutorial' do
        find('.enjoyhint_skip_btn').click

        # The tutorial disappears
        expect(page).not_to have_text 'Take a three minutes introduction tour to learn the most important features.'
        expect(page).not_to have_selector '.enjoyhint_next_btn'

        page.driver.browser.navigate.refresh

        # The tutorial did not start again
        expect(page).not_to have_text 'Take a three minutes introduction tour to learn the most important features.'
        expect(page).not_to have_selector '.enjoyhint_next_btn'
      end

      it 'and I continue the tutorial' do
        next_button.click
        expect(page).to have_text 'Please click on one of the projects with useful demo data to get started'

        find('.welcome').click_link 'Demo project'
        expect(page).to have_current_path "/projects/#{project.identifier}/work_packages?start_onboarding_tour=true"

        step_through_onboarding_wp_tour project, wp_1

        step_through_onboarding_main_menu_tour
      end
    end
  end
end


