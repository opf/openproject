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

RSpec.describe 'Projects index page',
               js: true,
               with_cuprite: true,
               with_settings: { login_required?: false } do
  shared_let(:admin) { create(:admin) }

  shared_let(:manager)   { create(:role, name: 'Manager') }
  shared_let(:developer) { create(:role, name: 'Developer') }

  shared_let(:custom_field) { create(:project_custom_field) }
  shared_let(:invisible_custom_field) { create(:project_custom_field, visible: false) }

  shared_let(:project) do
    create(:project,
           name: 'Plain project',
           identifier: 'plain-project')
  end
  shared_let(:public_project) do
    project = create(:project,
                     name: 'Public project',
                     identifier: 'public-project',
                     public: true)
    project.custom_field_values = { invisible_custom_field.id => 'Secret CF' }
    project.save
    project
  end
  shared_let(:development_project) do
    create(:project,
           name: 'Development project',
           identifier: 'development-project')
  end
  let(:news) { create(:news, project:) }
  let(:projects_page) { Pages::Projects::Index.new }

  def load_and_open_filters(user)
    login_as(user)
    projects_page.visit!
    projects_page.open_filters
  end

  def remove_filter(name)
    page.find("li[filter-name='#{name}'] .filter_rem").click
  end

  def expect_project_at_place(project, place)
    expect(page)
      .to have_selector("#project-table .project:nth-of-type(#{place}) td.name",
                        text: project.name)
  end

  def expect_projects_in_order(*projects)
    projects.each_with_index do |project, index|
      expect_project_at_place(project, index + 1)
    end
  end

  describe 'project visibility restriction' do
    context 'for an anonymous user' do
      specify 'only public projects shall be visible' do
        Role.anonymous
        visit projects_path

        expect(page).not_to have_text(project.name)
        expect(page).to have_text(public_project.name)

        # Test that the 'More' menu stays invisible on hover
        expect(page).not_to have_selector('.icon-show-more-horizontal')
      end
    end

    context 'for project members', with_ee: %i[custom_fields_in_projects_list] do
      shared_let(:user) do
        create(:user,
               member_in_project: development_project,
               member_through_role: developer,
               login: 'nerd',
               firstname: 'Alan',
               lastname: 'Turing')
      end

      specify 'only public projects or those the user is a member of shall be visible' do
        Role.non_member
        login_as(user)
        visit projects_path

        expect(page).to have_text(development_project.name)
        expect(page).to have_text(public_project.name)
        expect(page).not_to have_text(project.name)

        # Non-admin users shall not see invisible CFs.
        expect(page).not_to have_text(invisible_custom_field.name.upcase)
        expect(page).not_to have_select('add_filter_select', with_options: [invisible_custom_field.name])
      end
    end

    context 'for admins' do
      before do
        project.update(created_at: 7.days.ago, description: 'I am a nice project')

        news
      end

      specify 'all projects are visible' do
        login_as(admin)
        visit projects_path

        expect(page).to have_text(public_project.name)
        expect(page).to have_text(project.name)

        # Test visibility of 'more' menu list items
        item = page.first('tbody tr .icon-show-more-horizontal', visible: :all)
        item.hover
        item.click

        menu = page.first('tbody tr .project-actions')
        expect(menu).to have_text('Copy')
        expect(menu).to have_text('Project settings')
        expect(menu).to have_text('New subproject')
        expect(menu).to have_text('Delete')
        expect(menu).to have_text('Archive')

        # Test visibility of admin only properties
        within('#project-table') do
          expect(page)
            .to have_selector('th', text: 'REQUIRED DISK STORAGE')
          expect(page)
            .to have_selector('th', text: 'CREATED ON')
          expect(page)
            .to have_selector('td', text: project.created_at.strftime('%m/%d/%Y'))
          expect(page)
            .to have_selector('th', text: 'LATEST ACTIVITY AT')
          expect(page)
            .to have_selector('td', text: news.created_at.strftime('%m/%d/%Y'))
        end
      end

      specify 'flash sortBy is being escaped' do
        login_as(admin)
        visit projects_path(sortBy: "[[\"><script src='/foobar.js'></script>\",\"\"]]")

        error_text = "Orders ><script src='/foobar js'></script> is not set to one of the allowed values. and does not exist."
        error_html = "Orders &gt;&lt;script src='/foobar js'&gt;&lt;/script&gt; is not set to one of the allowed values. and does not exist."
        expect(page).to have_selector('.op-toast.-error', text: error_text)

        error_container = page.find('.op-toast.-error')
        expect(error_container['innerHTML']).to include error_html
      end
    end
  end

  context 'without valid Enterprise token' do
    specify 'CF columns and filters are not visible' do
      load_and_open_filters admin

      # CF's columns are not present:
      expect(page).not_to have_text(custom_field.name.upcase)
      # CF's filters are not present:
      expect(page).not_to have_select('add_filter_select', with_options: [custom_field.name])
    end
  end

  context 'with valid Enterprise token', with_ee: %i[custom_fields_in_projects_list] do
    specify 'CF columns and filters are not visible by default' do
      load_and_open_filters admin

      # CF's columns are not shown due to setting
      expect(page).not_to have_text(custom_field.name.upcase)
    end

    specify 'CF columns and filters are visible when added to settings' do
      Setting.enabled_projects_columns += [custom_field.column_name, invisible_custom_field.column_name]
      load_and_open_filters admin

      # CF's column is present:
      expect(page).to have_text(custom_field.name.upcase)
      # CF's filter is present:
      expect(page).to have_select('add_filter_select', with_options: [custom_field.name])

      # Admins shall be the only ones to see invisible CFs
      expect(page).to have_text(invisible_custom_field.name.upcase)
      expect(page).to have_select('add_filter_select', with_options: [invisible_custom_field.name])
    end
  end

  context 'when filtering with the global sidebar' do
    let(:current_user) { admin }

    before do
      Role.non_member
      login_as current_user
      projects_page.visit!
    end

    context 'with the "All projects" filter' do
      before do
        projects_page.set_sidebar_filter 'All projects'
      end

      it 'shows all active projects (default)' do
        projects_page.expect_projects_listed(project,
                                             public_project,
                                             development_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'active'
      end
    end

    context 'with the "My projects" filter' do
      shared_let(:member) do
        create(:user,
               member_in_project: project)
      end

      let(:current_user) { member }

      before do
        projects_page.set_sidebar_filter 'My projects'
      end

      it 'shows all projects I am a member of' do
        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project, development_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'member_of'
      end
    end

    context 'with the "Public projects" filter' do
      before do
        projects_page.set_sidebar_filter 'Public projects'
      end

      it 'shows all public projects' do
        projects_page.expect_projects_listed(public_project)
        projects_page.expect_projects_not_listed(project,
                                                 development_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'public'
      end
    end

    context 'with the "Archived projects" filter' do
      shared_let(:archived_project) do
        create(:project,
               name: 'Archived project',
               identifier: 'archived-project',
               active: false)
      end

      before do
        projects_page.set_sidebar_filter 'Archived projects'
      end

      it 'shows all archived projects' do
        projects_page.expect_projects_listed(archived_project, archived: true)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'active'
      end
    end
  end

  context 'with a filter set' do
    it 'only shows the matching projects and filters' do
      load_and_open_filters admin

      projects_page.set_filter('name_and_identifier',
                               'Name or identifier',
                               'contains',
                               ['Plain'])

      click_on 'Apply'
      # Filter is applied: Only the project that contains the the word "Plain" gets listed
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project)
      # Filter form is visible and the filter is still set.
      expect(page).to have_selector('li[filter-name="name_and_identifier"]')
    end
  end

  context 'when paginating' do
    before do
      allow(Setting).to receive(:per_page_options_array).and_return([1, 5])
    end

    it 'keeps applying filters and orders' do
      load_and_open_filters admin

      projects_page.set_filter('name_and_identifier',
                               'Name or identifier',
                               'doesn\'t contain',
                               ['Plain'])

      click_on 'Apply'
      wait_for_reload

      # Sorts ASC by name
      click_on 'Sort by "Name"'
      wait_for_reload

      # Results should be filtered and ordered ASC by name
      projects_page.expect_projects_listed(development_project)
      projects_page.expect_projects_not_listed(project,        # as it is filtered out
                                               public_project) # as it is on the second page
      expect(page).to have_text('Next') # as the result set is larger than 1

      # Changing the page size to 5 and back to 1 should not change the filters (which we test later on the second page)
      find('.op-pagination--options .op-pagination--item', text: '5').click # click page size '5'
      wait_for_reload
      find('.op-pagination--options .op-pagination--item', text: '1').click # return back to page size '1'
      wait_for_reload
      click_on '2' # Go to pagination page 2

      # On page 2 you should see the second page of the filtered set ordered ASC by name
      projects_page.expect_projects_listed(public_project)
      projects_page.expect_projects_not_listed(project,             # Filtered out
                                               development_project) # Present on page 1
      expect(page).not_to have_text('Next') # Filters kept active, so there is no third page.

      # Sorts DESC by name
      click_on 'Ascending sorted by "Name"'
      wait_for_reload

      # On page 2 the same filters should still be intact but the order should be DESC on name
      projects_page.expect_projects_listed(development_project)
      projects_page.expect_projects_not_listed(project,        # Filtered out
                                               public_project) # Present on page 1

      expect(page).not_to have_text('Next') # Filters kept active, so there is no third page.
      expect(page).to have_selector('.sort.desc', text: 'NAME')

      # Sending the filter form again what implies to compose the request freshly
      click_on 'Apply'
      wait_for_reload

      # We should see page 1, resetting pagination, as it is a new filter, but keeping the DESC order on the project
      # name
      projects_page.expect_projects_listed(public_project)
      projects_page.expect_projects_not_listed(development_project, # as it is on the second page
                                               project)             # as it filtered out
      expect(page).to have_text('Next') # as the result set is larger than 1
      expect(page).to have_selector('.sort.desc', text: 'NAME')
    end
  end

  context 'when filter of type' do
    specify 'Name and identifier gives results in both, name and identifier' do
      load_and_open_filters admin

      # Filter on model attribute 'name'
      projects_page.set_filter('name_and_identifier',
                               'Name or identifier',
                               'doesn\'t contain',
                               ['Plain'])

      click_on 'Apply'
      wait_for_reload

      projects_page.expect_projects_listed(development_project, public_project)
      projects_page.expect_projects_not_listed(project)

      # Filter on model attribute 'identifier'
      remove_filter('name_and_identifier')

      projects_page.set_filter('name_and_identifier',
                               'Name or identifier',
                               'is',
                               ['plain-project'])

      click_on 'Apply'
      wait_for_reload

      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, public_project)
    end

    describe 'Active or archived' do
      shared_let(:parent_project) do
        create(:project,
               name: 'Parent project',
               identifier: 'parent-project')
      end
      shared_let(:child_project) do
        create(:project,
               name: 'Child project',
               identifier: 'child-project',
               parent: parent_project)
      end

      specify 'filter on "status", archive and unarchive' do
        load_and_open_filters admin

        # value selection defaults to "active"'
        expect(page).to have_selector('li[filter-name="active"]')

        projects_page.expect_projects_listed(parent_project,
                                             child_project,
                                             project,
                                             development_project,
                                             public_project)

        accept_alert do
          projects_page.click_menu_item_of('Archive', parent_project)
        end
        wait_for_reload

        projects_page.expect_projects_not_listed(parent_project,
                                                 child_project) # The child project gets archived automatically

        projects_page.expect_projects_listed(project, development_project, public_project)

        visit project_overview_path(parent_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        # The child project gets archived automatically
        visit project_overview_path(child_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        load_and_open_filters admin

        projects_page.filter_by_active('no')

        projects_page.expect_projects_listed(parent_project, child_project, archived: true)

        # Test visibility of 'more' menu list items
        projects_page.activate_menu_of(parent_project) do |menu|
          expect(menu).to have_text('Unarchive')
          expect(menu).to have_text('Delete')
          expect(menu).not_to have_text('Archive')
          expect(menu).not_to have_text('Copy')
          expect(menu).not_to have_text('Settings')
          expect(menu).not_to have_text('New subproject')

          click_link('Unarchive')
        end

        # The child project does not get unarchived automatically
        visit project_path(child_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        visit project_path(parent_project)
        expect(page).to have_text(parent_project.name)

        load_and_open_filters admin

        projects_page.filter_by_active('yes')

        projects_page.expect_projects_listed(parent_project,
                                             project,
                                             development_project,
                                             public_project)
        projects_page.expect_projects_not_listed(child_project)
      end
    end

    describe 'I am member or not' do
      shared_let(:member) { create(:user, member_in_project: project) }

      it "filters for projects I'm a member on and those where I'm not" do
        Role.non_member
        load_and_open_filters member

        projects_page.expect_projects_listed(project, public_project)

        projects_page.filter_by_membership('yes')
        wait_for_reload

        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project, development_project)

        projects_page.filter_by_membership('no')
        wait_for_reload

        projects_page.expect_projects_listed(public_project)
        projects_page.expect_projects_not_listed(project, development_project)
      end
    end

    describe 'project status filter' do
      shared_let(:no_status_project) do
        # A project that doesn't have a status code set
        create(:project,
               name: 'No status project')
      end

      shared_let(:green_project) do
        # A project that has a status code set
        create(:project,
               status_code: 'on_track',
               name: 'Green project')
      end

      it 'sorts and filters on project status' do
        login_as(admin)
        projects_page.visit!

        click_link('Sort by "Status"')

        expect_project_at_place(green_project, 1)
        expect(page).to have_text('(1 - 5/5)')

        click_link('Ascending sorted by "Status"')

        expect_project_at_place(green_project, 5)
        expect(page).to have_text('(1 - 5/5)')

        projects_page.open_filters

        projects_page.set_filter('project_status_code',
                                 'Project status',
                                 'is (OR)',
                                 ['On track'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(green_project.name)
        expect(page).not_to have_text(no_status_project.name)

        projects_page.set_filter('project_status_code',
                                 'Project status',
                                 'is not empty',
                                 [])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(green_project.name)
        expect(page).not_to have_text(no_status_project.name)

        projects_page.set_filter('project_status_code',
                                 'Project status',
                                 'is empty',
                                 [])

        click_on 'Apply'
        wait_for_reload

        expect(page).not_to have_text(green_project.name)
        expect(page).to have_text(no_status_project.name)

        projects_page.set_filter('project_status_code',
                                 'Project status',
                                 'is not',
                                 ['On track'])

        click_on 'Apply'
        wait_for_reload

        expect(page).not_to have_text(green_project.name)
        expect(page).to have_text(no_status_project.name)
      end
    end

    describe 'other filter types', with_ee: %i[custom_fields_in_projects_list] do
      include ActiveSupport::Testing::TimeHelpers

      shared_let(:list_custom_field) { create(:list_project_custom_field) }
      shared_let(:date_custom_field) { create(:date_project_custom_field) }
      shared_let(:datetime_of_this_week) do
        today = Date.current
        # Ensure that the date is not today but still in the middle of the week to not run into week-start-issues here.
        date_of_this_week = today + ((today.wday % 7) > 2 ? -1 : 1)
        DateTime.parse("#{date_of_this_week}T11:11:11+00:00")
      end
      shared_let(:fixed_datetime) { DateTime.parse('2017-11-11T11:11:11+00:00') }

      shared_let(:project_created_on_today) do
        freeze_time
        project = create(:project,
                         name: 'Created today project')
        project.custom_field_values = { list_custom_field.id => list_custom_field.possible_values[2],
                                        date_custom_field.id => '2011-11-11' }
        project.save!
        project
      ensure
        travel_back
      end
      shared_let(:project_created_on_this_week) do
        travel_to(datetime_of_this_week)
        create(:project,
               name: 'Created on this week project')
      ensure
        travel_back
      end
      shared_let(:project_created_on_six_days_ago) do
        travel_to(DateTime.now - 6.days)
        create(:project,
               name: 'Created on six days ago project')
      ensure
        travel_back
      end
      shared_let(:project_created_on_fixed_date) do
        travel_to(fixed_datetime)
        create(:project,
               name: 'Created on fixed date project')
      ensure
        travel_back
      end
      shared_let(:todays_wp) do
        # This WP should trigger a change to the project's 'latest activity at' DateTime
        create(:work_package,
               updated_at: DateTime.now,
               project: project_created_on_today)
      end

      before do
        project_created_on_today
        load_and_open_filters admin
      end

      specify 'selecting operator' do
        # created on 'today' shows projects that were created today
        projects_page.set_filter('created_at',
                                 'Created on',
                                 'today')

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_this_week.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)

        # created on 'this week' shows projects that were created within the last seven days
        remove_filter('created_at')

        projects_page.set_filter('created_at',
                                 'Created on',
                                 'this week')

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to have_text(project_created_on_this_week.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)

        # created on 'on' shows projects that were created within the last seven days
        remove_filter('created_at')

        projects_page.set_filter('created_at',
                                 'Created on',
                                 'on',
                                 ['2017-11-11'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).not_to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_this_week.name)

        # created on 'less than days ago'
        remove_filter('created_at')

        projects_page.set_filter('created_at',
                                 'Created on',
                                 'less than days ago',
                                 ['1'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)

        # created on 'more than days ago'
        remove_filter('created_at')

        projects_page.set_filter('created_at',
                                 'Created on',
                                 'more than days ago',
                                 ['1'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).not_to have_text(project_created_on_today.name)

        # created on 'between'
        remove_filter('created_at')

        projects_page.set_filter('created_at',
                                 'Created on',
                                 'between',
                                 ['2017-11-10', '2017-11-12'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).not_to have_text(project_created_on_today.name)

        # Latest activity at 'today'. This spot check would fail if the data does not get collected from multiple tables
        remove_filter('created_at')

        projects_page.set_filter('latest_activity_at',
                                 'Latest activity at',
                                 'today')

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)

        # CF List
        remove_filter('latest_activity_at')

        projects_page.set_filter(list_custom_field.column_name,
                                 list_custom_field.name,
                                 'is (OR)',
                                 [list_custom_field.possible_values[2].value])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)

        # switching to multiselect keeps the current selection
        cf_filter = page.find("li[filter-name='#{list_custom_field.column_name}']")
        within(cf_filter) do
          # Initial filter is a 'single select'
          expect(cf_filter.find(:select, 'value')).not_to be_multiple
          click_on 'Toggle multiselect'
          # switching to multiselect keeps the current selection
          expect(cf_filter.find(:select, 'value')).to be_multiple
          expect(cf_filter).to have_select('value', selected: list_custom_field.possible_values[2].value)

          select list_custom_field.possible_values[3].value, from: 'value'
        end

        click_on 'Apply'
        wait_for_reload

        cf_filter = page.find("li[filter-name='#{list_custom_field.column_name}']")
        within(cf_filter) do
          # Query has two values for that filter, so it should show a 'multi select'.
          expect(cf_filter.find(:select, 'value')).to be_multiple
          expect(cf_filter)
            .to have_select('value',
                            selected: [list_custom_field.possible_values[2].value,
                                       list_custom_field.possible_values[3].value])

          # switching to single select keeps the first selection
          select list_custom_field.possible_values[1].value, from: 'value'
          unselect list_custom_field.possible_values[2].value, from: 'value'

          click_on 'Toggle multiselect'
          expect(cf_filter.find(:select, 'value')).not_to be_multiple
          expect(cf_filter).to have_select('value', selected: list_custom_field.possible_values[1].value)
          expect(cf_filter).not_to have_select('value', selected: list_custom_field.possible_values[3].value)
        end

        click_on 'Apply'
        wait_for_reload

        cf_filter = page.find("li[filter-name='#{list_custom_field.column_name}']")
        within(cf_filter) do
          # Query has one value for that filter, so it should show a 'single select'.
          expect(cf_filter.find(:select, 'value')).not_to be_multiple
        end

        # CF date filter work (at least for one operator)
        remove_filter(list_custom_field.column_name)

        projects_page.set_filter(date_custom_field.column_name,
                                 date_custom_field.name,
                                 'on',
                                 ['2011-11-11'])

        click_on 'Apply'
        wait_for_reload

        expect(page).to have_text(project_created_on_today.name)
        expect(page).not_to have_text(project_created_on_fixed_date.name)
      end

      pending "NOT WORKING YET: Date vs. DateTime issue: Selecting same date for from and to value shows projects of that date"
    end

    describe 'public filter' do
      it 'filters on "public" status' do
        load_and_open_filters admin

        projects_page.expect_projects_listed(project, public_project)

        projects_page.filter_by_public('no')
        wait_for_reload

        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project)

        load_and_open_filters admin

        projects_page.filter_by_public('yes')
        wait_for_reload

        projects_page.expect_projects_listed(public_project)
        projects_page.expect_projects_not_listed(project)
      end
    end
  end

  context 'for non-admins with role with permission' do
    shared_let(:can_copy_projects_role) do
      create(:role, name: 'Can Copy Projects Role', permissions: [:copy_projects])
    end
    shared_let(:can_add_subprojects_role) do
      create(:role, name: 'Can Add Subprojects Role', permissions: [:add_subprojects])
    end

    shared_let(:parent_project) do
      create(:project,
             name: 'Parent project',
             identifier: 'parent-project')
    end

    shared_let(:can_copy_projects_manager) do
      create(:user,
             member_in_project: parent_project,
             member_through_role: can_copy_projects_role)
    end
    shared_let(:can_add_subprojects_manager) do
      create(:user,
             member_in_project: parent_project,
             member_through_role: can_add_subprojects_role)
    end
    let(:simple_member) do
      create(:user,
             member_in_project: parent_project,
             member_through_role: developer)
    end

    before do
      # We are not admin so we need to force the built-in roles to have them.
      Role.non_member

      # Remove public projects from the default list for these scenarios.
      public_project.update(active: false)

      project.update(created_at: 7.days.ago)

      parent_project.enabled_module_names -= ["activity"]
      news
    end

    it 'can see the "More" menu' do
      # For a simple project member the 'More' menu is not visible.
      login_as(simple_member)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      # 'More' does not become visible on hover
      page.find('tbody tr').hover
      expect(page).not_to have_selector('.icon-show-more-horizontal')

      # For a project member with :copy_projects privilege the 'More' menu is visible.
      login_as(can_copy_projects_manager)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      # 'More' becomes visible on hover
      # because we use css opacity we can not test for the visibility changes
      page.find('tbody tr').hover
      expect(page).to have_selector('.icon-show-more-horizontal')

      # Test visibility of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('Copy')
      expect(menu).not_to have_text('New subproject')
      expect(menu).not_to have_text('Delete')
      expect(menu).not_to have_text('Archive')
      expect(menu).not_to have_text('Unarchive')

      # For a project member with :add_subprojects privilege the 'More' menu is visible.
      login_as(can_add_subprojects_manager)
      visit projects_path

      # 'More' becomes visible on hover
      # because we use css opacity we can not test for the visibility changes
      page.find('tbody tr').hover
      expect(page).to have_selector('.icon-show-more-horizontal')

      # Test visibility of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('New subproject')
      expect(menu).not_to have_text('Copy')
      expect(menu).not_to have_text('Delete')
      expect(menu).not_to have_text('Archive')
      expect(menu).not_to have_text('Unrchive')

      # Test admin only properties are invisible
      within('#project-table') do
        expect(page)
          .not_to have_selector('th', text: 'REQUIRED DISK STORAGE')
        expect(page)
          .not_to have_selector('th', text: 'CREATED ON')
        expect(page)
          .not_to have_selector('td', text: project.created_at.strftime('%m/%d/%Y'))
        expect(page)
          .not_to have_selector('th', text: 'LATEST ACTIVITY AT')
        expect(page)
          .not_to have_selector('td', text: news.created_at.strftime('%m/%d/%Y'))
      end
    end
  end

  describe 'order', with_ee: %i[custom_fields_in_projects_list] do
    shared_let(:integer_custom_field) { create(:int_project_custom_field) }
    # order is important here as the implementation uses lft
    # first but then reorders in ruby
    shared_let(:child_project_z) do
      create(:project,
             parent: project,
             name: "Z Child")
    end
    shared_let(:child_project_m) do
      create(:project,
             parent: project,
             name: "m Child") # intentionally written lowercase to test for case insensitive sorting
    end
    shared_let(:child_project_a) do
      create(:project,
             parent: project,
             name: "A Child")
    end

    before do
      login_as(admin)
      visit projects_path

      project.custom_field_values = { integer_custom_field.id => 1 }
      project.save!
      development_project.custom_field_values = { integer_custom_field.id => 2 }
      development_project.save!
      public_project.custom_field_values = { integer_custom_field.id => 3 }
      public_project.save!
      child_project_z.custom_field_values = { integer_custom_field.id => 4 }
      child_project_z.save!
      child_project_m.custom_field_values = { integer_custom_field.id => 4 }
      child_project_m.save!
      child_project_a.custom_field_values = { integer_custom_field.id => 4 }
      child_project_a.save!
    end

    it 'allows to alter the order in which projects are displayed' do
      Setting.enabled_projects_columns += [integer_custom_field.column_name]

      # initially, ordered by name asc on each hierarchical level
      expect_projects_in_order(development_project,
                               project,
                               child_project_a,
                               child_project_m,
                               child_project_z,
                               public_project)

      click_link('Name')
      wait_for_reload

      # Projects ordered by name asc
      expect_projects_in_order(child_project_a,
                               development_project,
                               child_project_m,
                               project,
                               public_project,
                               child_project_z)

      click_link('Name')
      wait_for_reload

      # Projects ordered by name desc
      expect_projects_in_order(child_project_z,
                               public_project,
                               project,
                               child_project_m,
                               development_project,
                               child_project_a)

      click_link(integer_custom_field.name)
      wait_for_reload

      # Projects ordered by cf asc first then project name desc
      expect_projects_in_order(project,
                               development_project,
                               public_project,
                               child_project_z,
                               child_project_m,
                               child_project_a)

      click_link('Sort by "Project hierarchy"')
      wait_for_reload

      # again ordered by name asc on each hierarchical level
      expect_projects_in_order(development_project,
                               project,
                               child_project_a,
                               child_project_m,
                               child_project_z,
                               public_project)
    end
  end

  describe 'blacklisted filter' do
    it 'is not visible' do
      load_and_open_filters admin

      expect(page).not_to have_select('add_filter_select', with_options: ["Principal"])
      expect(page).not_to have_select('add_filter_select', with_options: ["ID"])
      expect(page).not_to have_select('add_filter_select', with_options: ["Subproject of"])
    end
  end

  context 'with a multi-value custom field', with_ee: %i[custom_fields_in_projects_list] do
    let!(:list_custom_field) { create(:list_project_custom_field, multi_value: true) }

    before do
      project.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of('A'))
      project.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of('B'))

      project.save!

      allow(Setting)
        .to receive(:enabled_projects_columns)
        .and_return [list_custom_field.column_name]

      login_as(admin)
      visit projects_path
    end

    it 'shows the multi selection' do
      expected_sort = list_custom_field
                        .custom_options
                        .where(value: %w[A B])
                        .reorder(:id)
                        .pluck(:value)
      expect(page).to have_selector(".#{list_custom_field.column_name}.format-list", text: expected_sort.join(", "))
    end
  end

  describe 'project activity menu item' do
    context 'for projects with activity module enabled' do
      shared_let(:project_with_activity_enabled) { project }
      shared_let(:work_packages_viewer) { create(:role, name: 'Viewer', permissions: [:view_work_packages]) }
      shared_let(:simple_member) do
        create(:user,
               member_in_project: project_with_activity_enabled,
               member_through_role: work_packages_viewer)
      end
      shared_let(:work_package) { create(:work_package, project: project_with_activity_enabled) }

      before do
        project_with_activity_enabled.enabled_module_names += ["activity"]
        project_with_activity_enabled.save
      end

      it 'is displayed and redirects to project activity page with only project attributes visible' do
        login_as(simple_member)
        visit projects_path

        expect(page).to have_text(project.name)

        # 'More' becomes visible on hover
        # because we use css opacity we can not test for the visibility changes
        page.find('tbody tr').hover
        expect(page).to have_selector('.icon-show-more-horizontal')

        # "Project activity" item should be displayed in the 'more' menu
        page.find('tbody tr .icon-show-more-horizontal').click

        menu = page.find('tbody tr .project-actions')
        expect(menu).to have_text(I18n.t(:label_project_activity))

        # Clicking the menu item should redirect to project activity page
        # with only project attributes displayed
        menu.find_link(text: I18n.t(:label_project_activity)).click

        expect(page).to have_current_path(project_activity_index_path(project_with_activity_enabled), ignore_query: true)
        expect(page).to have_checked_field(id: 'event_types_project_attributes')
        expect(page).to have_unchecked_field(id: 'event_types_work_packages')
      end
    end
  end
end
