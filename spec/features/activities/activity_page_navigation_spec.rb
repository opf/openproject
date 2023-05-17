#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe 'Activity page navigation' do
  include ActiveSupport::Testing::TimeHelpers

  shared_let(:project) { create(:project, enabled_module_names: Setting.default_projects_modules + ['activity']) }
  shared_let(:subproject) do
    create(:project, parent: project, enabled_module_names: Setting.default_projects_modules + ['activity'])
  end
  shared_let(:user) do
    create(:user,
           member_in_projects: [project, subproject],
           member_with_permissions: %w[view_work_packages])
  end
  shared_let(:project_work_package) { create(:work_package, project:, subject: 'Work package for parent project') }
  shared_let(:subproject_work_package) { create(:work_package, project: subproject, subject: 'Work package for subproject') }
  shared_let(:project_older_work_package) do
    travel_to 45.days.ago
    create(:work_package, project:, subject: 'Work package older for parent project')
  ensure
    travel_back
  end
  shared_let(:subproject_older_work_package) do
    travel_to 45.days.ago
    create(:work_package, project: subproject, subject: 'Work package older for subproject')
  ensure
    travel_back
  end

  current_user { user }

  it 'stays on the same period when changing filters' do
    visit project_activity_index_path(project)
    click_link('Previous')

    expect(page)
      .to have_link(text: /#{subproject_older_work_package.subject}/)

    uncheck 'Include subprojects'
    click_button 'Apply'

    # Still on the same page. Filters applied. subproject work package created
    # 45 days ago should not be visible anymore
    expect(page)
      .not_to have_link(text: /#{subproject_older_work_package.subject}/)
  end

  shared_examples 'subprojects checkbox state is preserved' do
    it 'keeps Subprojects checked/unchecked when navigating between pages' do
      visit project_activity_index_path(project)

      aggregate_failures do
        # Subprojects is initially checked or not depending on a setting
        if Setting.display_subprojects_work_packages?
          expect(page).to have_checked_field('Include subprojects')
        else
          expect(page).to have_unchecked_field('Include subprojects')
        end

        # work packages for both projects are visible
        expect(page)
          .to have_link(text: /#{project_work_package.subject}/)
        expect(page)
          .to have_link(text: /#{subproject_work_package.subject}/)
      end

      uncheck 'Include subprojects'
      click_button 'Apply'

      aggregate_failures do
        expect(page).to have_unchecked_field('Include subprojects')
        expect(page)
          .to have_link(text: /#{project_work_package.subject}/)
        # work packages for subproject is not visible anymore
        expect(page)
          .not_to have_link(text: /#{subproject_work_package.subject}/)
      end

      click_link('Previous')

      aggregate_failures do
        # Subprojects should still be unchecked, bug #45348
        expect(page).to have_unchecked_field('Include subprojects')
        expect(page)
          .to have_link(text: /#{project_older_work_package.subject}/)

        # work packages for subproject still not visible
        expect(page)
          .not_to have_link(text: /#{subproject_older_work_package.subject}/)
      end

      click_link('Next')

      aggregate_failures do
        # Subprojects should still be unchecked, bug #45348
        expect(page).to have_unchecked_field('Include subprojects')
        expect(page)
          .to have_link(text: /#{project_work_package.subject}/)

        # work packages for subproject still not visible
        expect(page)
          .not_to have_link(text: /#{subproject_work_package.subject}/)
      end
    end
  end

  context 'with subprojects included by default', with_setting: { display_subprojects_work_packages: true } do
    include_examples 'subprojects checkbox state is preserved'
  end

  context 'with subprojects NOT included by default', with_setting: { display_subprojects_work_packages: false } do
    include_examples 'subprojects checkbox state is preserved'
  end

  context 'when navigating to a diff' do
    context 'for a project status explanation' do
      before do
        project.update(status_explanation: 'New status explanation')
      end

      def ensure_project_attributes_filter_is_checked
        # First visited activity page (activities_path) will set the
        # project attributes filter as checked and subsequent visits
        # to other activity pages will persist this setting

        if page.current_path == activities_path
          check 'Project attributes'
          click_button 'Apply'
        end
      end

      def assert_navigating_to_diff_page_and_back_comes_back_to_the_same_page(activity_page)
        visit(activity_page)
        activity_page_url = page.current_url

        ensure_project_attributes_filter_is_checked

        expect(page).to have_link(text: 'Details')
        expect(page.text).to include("Project status description set (Details)")
        within '.op-activity-list' do
          click_link('Details')
        end

        # on diff page, click the back button
        expect(page).to have_link(text: 'Back')
        click_link('Back')

        expect(page.current_url).to eq(activity_page_url)
      end

      it 'Back button navigates to the previously seen activity page' do
        [
          activities_path,
          project_activities_path(project),
          user_path(user)
        ].each do |activity_page|
          assert_navigating_to_diff_page_and_back_comes_back_to_the_same_page(activity_page)
        end
      end
    end

    context 'for a work package description' do
      before do
        project_work_package.update(description: 'New work package description')
      end

      def assert_navigating_to_diff_page_and_back_comes_back_to_the_same_page(activity_page)
        visit(activity_page)
        activity_page_url = page.current_url

        expect(page).to have_link(text: 'Details')
        expect(page.text).to include("Description changed (Details)")
        click_link('Details')

        # on diff page, click the back button
        expect(page).to have_link(text: 'Back')
        click_link('Back')

        expect(page.current_url).to eq(activity_page_url)
      end

      it 'Back button navigates to the previously seen activity page' do
        [
          activities_path,
          project_activities_path(project),
          user_path(user)
        ].each do |activity_page|
          assert_navigating_to_diff_page_and_back_comes_back_to_the_same_page(activity_page)
        end
      end

      # work package activity page is rendered by Angular, so it needs js: true
      it 'Back button navigates to the previously seen work package page', js: true do
        activity_page = work_package_path(project_work_package)
        assert_navigating_to_diff_page_and_back_comes_back_to_the_same_page(activity_page)
      end
    end
  end
end
