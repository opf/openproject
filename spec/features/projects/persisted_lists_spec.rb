# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe 'Persisted lists on projects index page',
               :js,
               :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  shared_let(:manager)   { create(:project_role, name: 'Manager') }
  shared_let(:developer) { create(:project_role, name: 'Developer') }

  shared_let(:custom_field) { create(:text_project_custom_field) }
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

  let(:projects_page) { Pages::Projects::Index.new }
  let(:my_projects_list) do
    create(:project_query, name: 'My projects list', user:) do |query|
      query.where('member_of', '=', OpenProject::Database::DB_VALUE_TRUE)

      query.save!
    end
  end
  let(:another_users_projects_list) do
    create(:project_query, name: 'Admin projects list', user: admin)
  end

  describe 'static lists in the sidebar' do
    let(:current_user) { admin }

    shared_let(:on_track_project) { create(:project, status_code: 'on_track') }
    shared_let(:off_track_project) { create(:project, status_code: 'off_track') }
    shared_let(:at_risk_project) { create(:project, status_code: 'at_risk') }

    before do
      ProjectRole.non_member
      login_as current_user
      projects_page.visit!
    end

    describe 'with the "Active projects" filter' do
      before do
        projects_page.set_sidebar_filter 'Active projects'
      end

      it 'shows all active projects (default)' do
        projects_page.expect_projects_listed(project,
                                             public_project,
                                             development_project,
                                             on_track_project,
                                             off_track_project,
                                             at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'active'
      end
    end

    context 'with the "My projects" filter' do
      shared_let(:member) do
        create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
      end

      let(:current_user) { member }

      before do
        projects_page.set_sidebar_filter 'My projects'
      end

      it 'shows all projects I am a member of' do
        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project,
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'member_of'
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
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'active'
      end
    end

    context 'with the "On track" filter' do
      before do
        projects_page.set_sidebar_filter 'On track'
      end

      it 'shows all projects having the on_track status' do
        projects_page.expect_projects_listed(on_track_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'project_status_code'
      end
    end

    context 'with the "Off track" filter' do
      before do
        projects_page.set_sidebar_filter 'Off track'
      end

      it 'shows all projects having the off_track status' do
        projects_page.expect_projects_listed(off_track_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 on_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'project_status_code'
      end
    end

    context 'with the "At risk" filter' do
      before do
        projects_page.set_sidebar_filter 'At risk'
      end

      it 'shows all projects having the off_track status' do
        projects_page.expect_projects_listed(at_risk_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set 'project_status_code'
      end
    end
  end

  describe 'persisting queries', with_settings: { enabled_projects_columns: %w[name project_status] } do
    current_user { user }

    let!(:project_member) { create(:member, principal: user, project:, roles: [developer]) }
    let!(:development_project_member) { create(:member, principal: user, project: development_project, roles: [developer]) }

    it 'allows saving, loading and deleting persisted filters and columns' do
      projects_page.visit!

      # The default filter is active
      projects_page.expect_title('Active projects')

      # Adding some filters
      projects_page.open_filters
      projects_page.filter_by_membership('yes')

      # By applying another filter, the title is changed as it does not longer match the default filter
      projects_page.expect_title('Projects')

      # The filters are applied
      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)

      projects_page.set_columns('Name')
      projects_page.expect_columns('Name')
      projects_page.expect_no_columns('Status')

      # Saving the query will lead to it being displayed in the sidebar
      projects_page.save_query('My saved query')

      projects_page.expect_sidebar_filter('My saved query', selected: false)

      # Opening the default filter again to reset the values
      projects_page.set_sidebar_filter('Active projects')

      projects_page.expect_projects_listed(project, public_project, development_project)
      projects_page.expect_columns('Name', 'Status')

      # Reloading the persisted query will reconstruct filters and columns
      projects_page.set_sidebar_filter('My saved query')

      projects_page.expect_title('My saved query')

      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)
      projects_page.expect_columns('Name')
      projects_page.expect_no_columns('Status')

      # The query can be deleted
      projects_page.delete_query

      # It will then also be removed from the sidebar
      projects_page.expect_no_sidebar_filter('My saved query')
      # And the default filter will be active again
      projects_page.expect_title('Active projects')
      projects_page.expect_projects_listed(project, public_project, development_project)
      projects_page.expect_columns('Name', 'Status')
    end
  end

  describe 'persisted filters' do
    current_user { user }

    let(:another_project) do
      create(:project,
             name: 'Another project',
             identifier: 'another-project')
    end

    let!(:project_member) { create(:member, principal: user, project:, roles: [developer]) }
    let!(:development_project_member) { create(:member, principal: user, project: development_project, roles: [developer]) }
    let!(:another_project_member) { create(:member, principal: user, project: another_project, roles: [developer]) }

    before do
      another_users_projects_list
      my_projects_list

      allow(Setting).to receive(:per_page_options_array).and_return([1, 2])
    end

    it 'keep the query active when applying orders and page changes' do
      projects_page.visit!

      # The user can select the list but cannot see another user's list
      projects_page.set_sidebar_filter(my_projects_list.name)
      projects_page.expect_no_sidebar_filter(another_users_projects_list.name)

      # Sorts ASC by name
      projects_page.sort_by('Name')

      # Results should be filtered and ordered ASC by name and the user is still on the first page
      projects_page.expect_title(my_projects_list.name)
      projects_page.expect_projects_listed(another_project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               project,             # Because it is on the third page
                                               public_project)      # Because it is filtered out
      projects_page.expect_current_page_number(1)

      projects_page.got_to_page(2)

      # The title is kept
      projects_page.expect_title(my_projects_list.name)
      # The filters are still active
      projects_page.expect_projects_listed(development_project)
      projects_page.expect_projects_not_listed(another_project,     # Because it is on the first page
                                               project,             # Because it is on the third page
                                               public_project)      # Because it is filtered out

      # Sorts DESC by name
      projects_page.sort_by('Name')

      # The title is kept
      projects_page.expect_title(my_projects_list.name)
      # The filters are still active but the page is reset so that the user is on the first page again
      projects_page.expect_current_page_number(1)
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               another_project,     # Because it is on the third page
                                               public_project)      # Because it is filtered out

      # Move to the third page
      projects_page.got_to_page(3)

      projects_page.expect_projects_listed(another_project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               project,             # Because it is on the first page
                                               public_project)      # Because it is filtered out

      # Changing the page size
      projects_page.set_page_size(2)

      # The filters and order are kept and the user is on the first page
      projects_page.expect_current_page_number(1)
      projects_page.expect_projects_listed(project,
                                           development_project) # Because of the increased page size, it is now displayed
      projects_page.expect_projects_not_listed(another_project,    # Because it is on the second page
                                               public_project)     # Because it is filtered out

      projects_page.got_to_page(2)

      # But if filters are applied, the sort order is kept, the title is lost and the page number is reset
      projects_page.open_filters
      projects_page.remove_filter('member_of')
      projects_page.filter_by_active('yes')

      # Using the default filter again
      projects_page.expect_title('Projects')
      projects_page.expect_current_page_number(1)

      projects_page.expect_projects_listed(project,
                                           public_project) # Because it is now in the filter set
      projects_page.expect_projects_not_listed(another_project, # Because it is on the second page
                                               development_project) # Because it is on the second page
    end

    it 'cannot access another user`s list' do
      visit projects_path(query_id: another_users_projects_list.id)

      expect(page)
        .to have_no_text(another_users_projects_list.name)
      expect(page)
        .to have_text('You are not authorized to access this page.')
    end
  end
end
