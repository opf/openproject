#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/projects/projects_page'


describe 'Projects index page', type: :feature, js: true, with_settings: { login_required?: false } do
  let!(:admin) { FactoryGirl.create :admin, firstname: 'Admin', lastname: 'Larmin', login: 'admin' }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let!(:custom_field) { FactoryGirl.create :project_custom_field }
  let!(:invisible_custom_field) { FactoryGirl.create :project_custom_field, visible: false }

  let!(:project) { FactoryGirl.create(:project, name: 'Plain project', identifier: 'plain-project') }
  let!(:public_project) do
    project = FactoryGirl.create(:project,
                       name: 'Public project',
                       identifier: 'public-project',
                       is_public: true)
    project.custom_field_values = { invisible_custom_field.id => 'Secret CF'}
    project.save
    project
  end
  let!(:development_project) do
    FactoryGirl.create(:project,
                       name: 'Development project',
                       identifier: 'development-project')
  end

  def visit_list_and_open_filter_form_as(user)
    login_as(user)
    visit projects_path
    click_button('Show/hide filters')
  end

  def set_filter(name, human_name, human_operator = nil, values = [])
    select human_name, from: 'add_filter_select'
    selected_filter = page.find("li[filter-name='#{name}']")
    within(selected_filter) do
      select human_operator, from: 'operator'
      if values.any?
        case name
        when 'name_and_identifier'
          fill_in 'value', with: values.first
        when 'status'
          if values.size == 1
            select values.first, from: 'value'
          end
        when 'created_on'
          case human_operator
          when 'on'
            fill_in 'value', with: values.first
          when 'less than days ago'
            fill_in 'value', with: values.first
          when 'more than days ago'
            fill_in 'value', with: values.first
          when 'days ago'
            fill_in 'value', with: values.first
          when 'between'
            fill_in 'from_value', with: values.first
            fill_in 'to_value', with: values.second
          end
        when /cf_[\d]+/
          if selected_filter[:'filter-type'] == 'list_optional'
            if values.size == 1
              value_select = find('.single-select select[name="value"]')
              value_select.select values.first
            end
          elsif selected_filter[:'filter-type'] == 'date'
            if human_operator == 'on'
              fill_in 'value', with: values.first
            end
          end
        end
      end
    end
  end

  feature 'restricts project visibility' do
    feature 'for a anonymous user' do
      scenario 'only public projects shall be visible' do
        visit projects_path

        expect(page).to_not have_text(project.name)
        expect(page).to have_text(public_project.name)

        # Test that the 'More' menu stays invisible on hover
        page.find('tbody tr').hover
        expect(page).to_not have_css('.icon-show-more-horizontal')
      end
    end

    feature 'for project members' do
      let!(:user) do
        FactoryGirl.create(:user,
                           member_in_project: development_project,
                           member_through_role: developer,
                           login: 'nerd',
                           firstname: 'Alan',
                           lastname: 'Turing')
      end

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:custom_fields_in_projects_list).and_return(true)
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
      end

      scenario 'only public project or those the user is member of shall be visible' do
        Role.non_member
        login_as(user)
        visit projects_path
        expect(page).to have_text(development_project.name)
        expect(page).to have_text(public_project.name)
        expect(page).to_not have_text(project.name)

        # Non-admin users shall not see invisible CFs.
        expect(page).to_not have_text(invisible_custom_field.name.upcase)
        expect(page).to_not have_select('add_filter_select', :with_options => [invisible_custom_field.name])
      end
    end

    feature 'for admins' do
      scenario 'test that all projects are visible' do
        login_as(admin)
        visit projects_path

        expect(page).to have_text(public_project.name)
        expect(page).to have_text(project.name)

        # Test that the 'More' menu becomes visible on hover
        expect(page).to_not have_css('.icon-show-more-horizontal')
        page.first('tbody tr').hover
        expect(page).to have_css('.icon-show-more-horizontal')

        # Test visiblity of 'more' menu list items
        page.first('tbody tr .icon-show-more-horizontal').click
        menu = page.first('tbody tr .project-actions')
        expect(menu).to have_text('Copy')
        expect(menu).to have_text('New subproject')
        expect(menu).to have_text('Delete')
        expect(menu).to have_text('Archive')
      end
      pending "test that not 'visible' CFs are visible"
    end
  end

  feature 'without valid Enterprise token' do
    scenario 'CF columns and filters are not visible' do
      visit_list_and_open_filter_form_as admin

      # CF's columns are not present:
      expect(page).to_not have_text(custom_field.name.upcase)
      # CF's filters are not present:
      expect(page).to_not have_select('add_filter_select', with_options: [custom_field.name])
    end
  end

  feature 'with valid Enterprise token' do
    before do
      allow(EnterpriseToken).to receive(:allows_to?).with(:custom_fields_in_projects_list).and_return(true)
      allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
    end

    scenario 'CF columns and filters are visible' do
      visit_list_and_open_filter_form_as admin

      # CF's column is present:
      expect(page).to have_text(custom_field.name.upcase)
      # CF's filter is present:
      expect(page).to have_select('add_filter_select', with_options: [custom_field.name])

      # Admins shall be the only ones to see invisible CFs
      expect(page).to have_text(invisible_custom_field.name.upcase)
      expect(page).to have_select('add_filter_select', :with_options => [invisible_custom_field.name])
    end

    scenario
  end

  feature 'with a filter set' do
    scenario 'it should only show the matching projects and filters' do
      visit_list_and_open_filter_form_as admin

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'contains',
                 ['Plain'])

      click_on 'Filter'
      # Filter is applied: Only the project that contains the the word "Plain" gets listed
      expect(page).to_not have_text(public_project.name)
      expect(page).to have_text(project.name)
      # Filter form is visible and the filter is still set.
      expect(page).to have_css('li[filter-name="name_and_identifier"]')
    end
  end

  feature 'when paginating' do
    before do
      allow(Setting).to receive(:per_page_options_array).and_return([1])
    end

    scenario 'it keeps applying filters and order' do
      visit_list_and_open_filter_form_as admin

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'doesn\'t contain',
                 ['Plain'])

      click_on 'Filter'

      # Sorts ASC by name
      click_on 'Sort by "Project"'

      # Results should be filtered and ordered ASC by name
      expect(page).to have_text(development_project.name)
      expect(page).to_not have_text(project.name)        # as it filtered away
      expect(page).to have_text('Next')          # as the result set is larger than 1
      expect(page).to_not have_text(public_project.name) # as it is on the second page

      click_on '2' # Go to pagination page 2

      # On page 2 you should see the second page of the filtered set ordered ASC by name
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(project.name)             # Filtered away
      expect(page).to_not have_text('Next')                   # Filters kept active, so there is no third page.
      expect(page).to_not have_text(development_project.name) # That one should be on page 1

      # Sorts DESC by name
      click_on 'Ascending sorted by "Project"'

      # On page 2 the same filters should still be intact but the order should be DESC on name
      expect(page).to have_text(development_project.name)
      expect(page).to_not have_text(project.name)        # Filtered away
      expect(page).to_not have_text('Next')              # Filters kept active, so there is no third page.
      expect(page).to_not have_text(public_project.name) # That one should be on page 1

      # Sending the filter form again what implies to compose the request freshly
      click_on 'Filter'

      # We should see page 1, resetting pagination, as it is a new filter, but keeping the DESC order on the project
      # name
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(development_project.name) # as it is on the second page
      expect(page).to_not have_text(project.name)             # as it filtered away
      expect(page).to have_text('Next')               # as the result set is larger than 1
    end
  end

  feature 'when filter of type' do

    scenario 'Name and identifier gives results in both, name and identifier' do
      visit_list_and_open_filter_form_as admin

      # Filter on model attribute 'name'
      set_filter('name_and_identifier',
                 'Name or identifier',
                 'doesn\'t contain',
                 ['Plain'])

      click_on 'Filter'

      expect(page).to have_text(development_project.name)
      expect(page).to have_text(public_project.name)
      expect(page).to_not have_text(project.name)

      # Filter on model attribute 'identifier'
      page.find('li[filter-name="name_and_identifier"] .filter_rem').click

      set_filter('name_and_identifier',
                 'Name or identifier',
                 'is',
                 ['plain-project'])

      click_on 'Filter'

      expect(page).to have_text(project.name)
      expect(page).to_not have_text(development_project.name)
      expect(page).to_not have_text(public_project.name)
    end

    feature 'Active or archived' do
      let!(:archived_project) do
        FactoryGirl.create(:project,
                           name: 'Archived project',
                           identifier: 'archived-project',
                           status: Project::STATUS_ARCHIVED)
      end

      scenario 'filter on "status"' do
        visit_list_and_open_filter_form_as admin

        # value selection defaults to "active"'
        expect(page).to have_css('li[filter-name="status"]')

        # Filter has three operators 'all', 'active' and 'archived'
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="*"]')).to have_text('all')
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="="]')).to have_text('is')
        expect(page.find('li[filter-name="status"] select[name="operator"] option[value="!"]')).to have_text('is not')

        expect(page).to_not have_text('Archived project')
        expect(page).to have_text('Plain project')
        expect(page).to have_text('Development project')
        expect(page).to have_text('Public project')

        # Filter on model attribute 'status'
        set_filter('status',
                   'Active or archived',
                   'is',
                   ['archived'])

        click_on 'Filter'

        # Test visiblity of 'more' menu list items
        page.find('tbody tr').hover
        page.find('tbody tr .icon-show-more-horizontal').click
        menu = page.find('tbody tr .project-actions')
        expect(menu).to have_text('Unarchive')
        expect(menu).to have_text('Delete')
        expect(menu).to_not have_text('Archive')
        expect(menu).to_not have_text('Copy')
        expect(menu).to_not have_text('Settings')
        expect(menu).to_not have_text('New subproject')
      end
    end

    feature 'other filter types' do
      let!(:list_custom_field) { FactoryGirl.create :list_project_custom_field }
      let!(:date_custom_field) { FactoryGirl.create :date_project_custom_field }
      let(:datetime_of_this_week) do
        today = Date.today
        # Ensure that the date is not today but in the middle of the week
        date_of_this_week = today + (((today.wday) % 7) > 2 ? -1 : 1)
        DateTime.parse(date_of_this_week.to_s + 'T11:11:11+00:00')
      end
      let(:fixed_datetime) { DateTime.parse('2017-11-11T11:11:11+00:00') }

      let!(:project_created_on_today) do
        project = FactoryGirl.create(:project,
                           name: 'Created today project',
                           created_on: DateTime.now)
        project.custom_field_values = { list_custom_field.id => '3'}
        project.custom_field_values = { date_custom_field.id => '2011-11-11'}
        project.save
        project
      end
      let!(:project_created_on_this_week) do
        FactoryGirl.create(:project,
                           name: 'Created on this week project',
                           created_on: datetime_of_this_week)
      end
      let!(:project_created_on_six_days_ago) do
        FactoryGirl.create(:project,
                           name: 'Created on six days ago project',
                           created_on: DateTime.now - 6.days)
      end
      let!(:project_created_on_fixed_date) do
        FactoryGirl.create(:project,
                           name: 'Created on fixed date project',
                           created_on: fixed_datetime)
      end
      let!(:todays_wp) do
        # This WP should trigger a change to the project's 'latest activity at' DateTime
        FactoryGirl.create(:work_package, updated_at: DateTime.now, project: project_created_on_today)
      end

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:custom_fields_in_projects_list).and_return(true)
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
        project_created_on_today
        visit_list_and_open_filter_form_as admin
      end

      scenario 'selecting operator' do
        # created on 'today' shows projects that were created today
        set_filter('created_on',
                   'Created on',
                   'today')

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_this_week.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'this week' shows projects that were created within the last seven days
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('created_on',
                   'Created on',
                   'this week')

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to have_text(project_created_on_this_week.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'on' shows projects that were created within the last seven days
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('created_on',
                   'Created on',
                   'on',
                    ['2017-11-11'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_this_week.name)

        # created on 'less than days ago'
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('created_on',
                   'Created on',
                   'less than days ago',
                   ['1'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # created on 'more than days ago'
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('created_on',
                   'Created on',
                   'more than days ago',
                   ['1'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)

        # created on 'between'
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('created_on',
                   'Created on',
                   'between',
                   ['2017-11-10', '2017-11-12'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_fixed_date.name)
        expect(page).to_not have_text(project_created_on_today.name)

        # Latest activity at 'today'. This spot check would fail if the data does not get collected from multiple tables
        page.find('li[filter-name="created_on"] .filter_rem').click

        set_filter('latest_activity_at',
                   'Latest activity at',
                   'today')

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # CF List
        page.find('li[filter-name="latest_activity_at"] .filter_rem').click

        set_filter("cf_#{list_custom_field.id}",
                   list_custom_field.name,
                   'is',
                   ['3'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)

        # switching to multiselect keeps the current selection
        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Initial filter is a 'single select'
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
          click_on 'Toggle multiselect'
          # switching to multiselect keeps the current selection
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_truthy
          expect(cf_filter).to have_select('value', selected: '3')

          select '5', from: 'value'
        end

        click_on 'Filter'

        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Query has two values for that filter, so it shoud show a 'multi select'.
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_truthy
          expect(cf_filter).to have_select('value', selected: ['3', '5'])

          # switching to single select keeps the first selection
          select '2', from: 'value'
          unselect '3', from: 'value'

          click_on 'Toggle multiselect'
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
          expect(cf_filter).to have_select('value', selected: '2')
          expect(cf_filter).to_not have_select('value', selected: '5')
        end

        click_on 'Filter'

        cf_filter = page.find("li[filter-name='cf_#{list_custom_field.id}']")
        within(cf_filter) do
          # Query has one value for that filter, so it should show a 'single select'.
          expect(cf_filter.find(:select, 'value')[:multiple]).to be_falsey
        end

        # CF date filter work (at least for one operator)
        page.find("li[filter-name='cf_#{list_custom_field.id}'] .filter_rem").click

        set_filter("cf_#{date_custom_field.id}",
                   date_custom_field.name,
                   'on',
                   ['2011-11-11'])

        click_on 'Filter'

        expect(page).to have_text(project_created_on_today.name)
        expect(page).to_not have_text(project_created_on_fixed_date.name)
      end

      pending "NOT WORKING YET: Date vs. DateTime issue: Selecting same date for from and to value shows projects of that date"
    end
  end

  feature 'Non-admins with role with permission' do
    let!(:can_copy_projects_role) do
      FactoryGirl.create :role, name: 'Can Copy Projects Role', permissions: [:copy_projects]
    end
    let!(:can_add_subprojects_role) do
      FactoryGirl.create :role, name: 'Can Add Subprojects Role', permissions: [:add_subprojects]
    end

    let!(:parent_project) do
      FactoryGirl.create(:project,
                         name: 'Parent project',
                         identifier: 'parent-project' )
    end

    let!(:can_copy_projects_manager) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: can_copy_projects_role)
    end
    let!(:can_add_subprojects_manager) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: can_add_subprojects_role)
    end
    let!(:simple_member) do
      FactoryGirl.create(:user,
                         member_in_project: parent_project,
                         member_through_role: developer)
    end

    before do
      # We are not admin so we need to force the built-in roles to have them.
      Role.non_member

      # Remove public projects from the default list for these scenarios.
      public_project.update_attribute :status, Project::STATUS_ARCHIVED
    end

    scenario 'can see the "More" menu' do
      # For a simple project member the 'More' menu is not visible.
      login_as(simple_member)
      visit projects_path

      expect(page).to have_text('Parent project')

      # 'More' menu should be invisible by default
      expect(page).not_to have_css('.icon-show-more-horizontal')

      # 'More' does not become visible on hover
      page.find('tbody tr').hover
      expect(page).to_not have_css('.icon-show-more-horizontal')


      # For a project member with :copy_projects privilege the 'More' menu is visible.
      login_as(can_copy_projects_manager)
      visit projects_path

      expect(page).to have_text('Parent project')

      # 'More' menu should be invisible by default
      expect(page).not_to have_css('.icon-show-more-horizontal')

      # 'More' becomes visible on hover
      page.find('tbody tr').hover
      expect(page).to have_css('.icon-show-more-horizontal')

      # Test visiblity of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('Copy')
      expect(menu).to_not have_text('New subproject')
      expect(menu).to_not have_text('Delete')
      expect(menu).to_not have_text('Archive')
      expect(menu).to_not have_text('Unarchive')


      # For a project member with :add_subprojects privilege the 'More' menu is visible.
      login_as(can_add_subprojects_manager)
      visit projects_path

      # 'More' menu should be invisible by default
      expect(page).not_to have_css('.icon-show-more-horizontal')

      # 'More' becomes visible on hover
      page.find('tbody tr').hover
      expect(page).to have_css('.icon-show-more-horizontal')

      # Test visiblity of 'more' menu list items
      page.find('tbody tr .icon-show-more-horizontal').click
      menu = page.find('tbody tr .project-actions')
      expect(menu).to have_text('New subproject')
      expect(menu).to_not have_text('Copy')
      expect(menu).to_not have_text('Delete')
      expect(menu).to_not have_text('Archive')
      expect(menu).to_not have_text('Unrchive')
    end
  end
end
