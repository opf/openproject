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

    describe 'with the "All projects" filter' do
      before do
        projects_page.set_sidebar_filter 'All projects'
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

  describe 'persisting queries' do
    current_user { admin }

    let!(:member) { create(:member, principal: admin, project:, roles: [developer]) }

    it 'allows saving, loading and deleting persisted filters' do
      projects_page.visit!

      # Adding some filters
      projects_page.open_filters
      projects_page.filter_by_membership('yes')

      # The filters are applied
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project, development_project)

      # Saving the query will lead to it being displayed in the sidebar
      projects_page.save_query('My saved query')

      projects_page.expect_sidebar_filter('My saved query', selected: false)

      # Opening the default filter again to reset the values
      projects_page.set_sidebar_filter('All projects')

      projects_page.expect_projects_listed(project, public_project, development_project)

      # Reloading the persisted query will reconstruct filters and columns
      projects_page.set_sidebar_filter('My saved query')

      projects_page.expect_title('My saved query')

      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project, development_project)

      # The query can be deleted
      projects_page.delete_query

      # It will then also be removed from the sidebar
      projects_page.expect_no_sidebar_filter('My saved query')
    end
  end
end
