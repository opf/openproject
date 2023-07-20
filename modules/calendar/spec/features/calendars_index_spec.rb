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
require_relative '../support/pages/calendar'

RSpec.describe 'Calendars', 'index', :js, :with_cuprite do
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking calendar_view])
  end

  shared_let(:other_project) do
    create(:project, enabled_module_names: %w[work_package_tracking calendar_view])
  end

  shared_let(:user) do
    create(:user,
           member_in_projects: [project, other_project],
           member_with_permissions: %w[
             view_work_packages
             edit_work_packages
             save_queries
             save_public_queries
             view_calendar
             manage_calendars
           ])
  end

  let(:query) do
    create(:query_with_view_work_packages_calendar,
           project:,
           user:,
           public: true)
  end
  let(:other_query) do
    create(:query_with_view_work_packages_calendar,
           project: other_project,
           user:,
           public: true)
  end

  let(:current_user) { user }

  context 'when navigating to the global index page', with_flag: { more_global_index_pages: true } do
    shared_examples 'global index page is reachable' do
      it 'is reachable' do
        expect(page).to have_current_path(calendars_path)
        expect(page).to have_text 'There is currently nothing to display.'
        expect(page).to have_selector '#main-menu'
      end
    end

    before do
      login_as current_user
      visit root_path
      wait_for_reload
    end

    context 'with the modules menu' do
      before do
        find("a[title='Modules']").click

        within '#more-menu' do
          click_on 'Calendars'
        end
      end

      it_behaves_like 'global index page is reachable'
    end

    context 'with the global menu' do
      before do
        within '#main-menu' do
          click_on 'Calendars'
        end
      end

      it_behaves_like 'global index page is reachable'
    end
  end

  context 'when visiting from a global context', with_flag: { more_global_index_pages: true } do
    let(:calendars_page) { Pages::Calendar.new(nil) }
    let(:queries) { [query, other_query] }

    before do
      login_as current_user
      queries
      visit calendars_path
    end

    context 'with permissions to globally manage calendars' do
      it 'shows no create button' do
        calendars_page.expect_no_create_button
      end
    end

    context 'with no views' do
      let(:queries) { [] }

      it 'shows an empty index page' do
        calendars_page.expect_no_views_visible
      end
    end

    context 'with existing views' do
      it 'shows those views', :aggregate_failures do
        queries.each do |q|
          calendars_page.expect_view_visible(q)
          calendars_page.expect_no_delete_button(q)
        end
      end
    end

    context 'with another user with limited access' do
      let(:current_user) do
        create(:user,
               firstname: 'Bernd',
               member_in_project: project,
               member_with_permissions: %w[view_work_packages view_calendar])
      end

      context 'and the view is non-public' do
        let(:query) { create(:query, user:, project:, public: false) }

        it 'does not show a non-public view' do
          calendars_page.expect_no_views_visible
          calendars_page.expect_view_not_visible query

          calendars_page.expect_no_delete_button query
        end
      end
    end
  end

  context 'when visiting from a project-specific context' do
    let(:calendars_page) { Pages::Calendar.new(project) }

    before do
      login_as current_user
      query
      visit project_calendars_path(project)
    end

    context 'with no views' do
      let(:query) { nil }

      it 'shows an empty index page' do
        calendars_page.expect_no_views_visible
        calendars_page.expect_create_button
      end
    end

    context 'with an existing view' do
      it 'shows that view' do
        calendars_page.expect_view_visible query
        calendars_page.expect_delete_button query
      end

      context 'with another user with limited access' do
        let(:current_user) do
          create(:user,
                 firstname: 'Bernd',
                 member_in_project: project,
                 member_with_permissions: %w[view_work_packages view_calendar])
        end

        it 'does not show the management buttons' do
          calendars_page.expect_view_visible query

          calendars_page.expect_no_delete_button query
          calendars_page.expect_no_create_button
        end

        context 'when the view is non-public' do
          let(:query) { create(:query, user:, project:, public: false) }

          it 'does not show a non-public view' do
            calendars_page.expect_no_views_visible
            calendars_page.expect_view_not_visible query

            calendars_page.expect_no_create_button
          end
        end
      end
    end
  end
end
