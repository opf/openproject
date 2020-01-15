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

require_relative '../support/pages/dashboard'

describe 'Arbitrary WorkPackage query table widget dashboard', type: :feature, js: true, with_mail: false do
  let!(:type) { FactoryBot.create :type }
  let!(:other_type) { FactoryBot.create :type }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:other_project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:type_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:other_type_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: other_type,
                      author: user,
                      responsible: user
  end
  let!(:other_project_work_package) do
    FactoryBot.create :work_package,
                      project: other_project,
                      type: type,
                      author: user,
                      responsible: user
  end

  let(:permissions) do
    %i[view_work_packages
       add_work_packages
       save_queries
       manage_public_queries
       view_dashboards
       manage_dashboards]
  end

  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end

  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, user: u, roles: [role])
      FactoryBot.create(:member, project: other_project, user: u, roles: [role])
    end
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { ::Components::WorkPackages::TableConfiguration::Filters.new }
  let(:columns) { ::Components::WorkPackages::Columns.new }

  before do
    login_as user

    dashboard_page.visit!
  end

  context 'with the permission to save queries' do
    it 'can add the widget and see the work packages of the filtered for types' do
      dashboard_page.add_widget(1, 1, :row, "Work packages table")

      sleep(0.2)

      filter_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')

      filter_area.expect_to_span(1, 1, 2, 3)

      # At the beginning, the default query is displayed
      expect(filter_area.area)
        .to have_selector('.subject', text: type_work_package.subject)

      expect(filter_area.area)
        .to have_selector('.subject', text: other_type_work_package.subject)

      # Work packages from other projects are not displayed as the query is project scoped
      expect(filter_area.area)
        .not_to have_selector('.subject', text: other_project_work_package.subject)

      # User has the ability to modify the query

      filter_area.configure_wp_table
      modal.switch_to('Filters')
      filters.expect_filter_count(2)
      filters.add_filter_by('Type', 'is', type.name)
      modal.save

      filter_area.configure_wp_table
      modal.switch_to('Columns')
      columns.assume_opened
      columns.remove 'Subject'

      expect(filter_area.area)
        .to have_selector('.id', text: type_work_package.id)

      # as the Subject column is disabled
      expect(filter_area.area)
        .to have_no_selector('.subject', text: type_work_package.subject)

      # As other_type is filtered out
      expect(filter_area.area)
        .to have_no_selector('.id', text: other_type_work_package.id)

      # Work packages from other projects are not displayed as the query is project scoped
      expect(filter_area.area)
        .not_to have_selector('.subject', text: other_project_work_package.subject)

      scroll_to_element(filter_area.area)
      within filter_area.area do
        input = find('.editable-toolbar-title--input')
        input.set('My WP Filter')
        input.native.send_keys(:return)
      end

      sleep(1)

      # The whole of the configuration survives a reload
      # as it is persisted in the grid

      visit root_path
      dashboard_page.visit!

      filter_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')
      expect(filter_area.area)
        .to have_selector('.id', text: type_work_package.id)

      # as the Subject column is disabled
      expect(filter_area.area)
        .to have_no_selector('.subject', text: type_work_package.subject)

      # As other_type is filtered out
      expect(filter_area.area)
        .to have_no_selector('.id', text: other_type_work_package.id)

      # Work packages from other projects are not displayed as the query is project scoped
      expect(filter_area.area)
        .not_to have_selector('.subject', text: other_project_work_package.subject)

      within filter_area.area do
        expect(page).to have_field('editable-toolbar-title', with: 'My WP Filter', wait: 10)
      end
    end
  end

  context 'without the permission to save queries' do
    let(:permissions) { %i[view_work_packages add_work_packages view_dashboards manage_dashboards] }

    it 'cannot add the widget' do
      dashboard_page.expect_unable_to_add_widget(1, 1, :within, "Work packages table")
    end
  end
end
