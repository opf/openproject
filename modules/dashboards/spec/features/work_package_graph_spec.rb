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

require_relative '../support/pages/dashboard'

describe 'Arbitrary WorkPackage query graph widget dashboard', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:other_type) { FactoryBot.create :type }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:other_project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:closed_status) { FactoryBot.create :status, is_closed: true }
  let!(:type_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user,
                      status: open_status,
                      responsible: user
  end
  let!(:other_type_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: other_type,
                      author: user,
                      status: closed_status,
                      responsible: user
  end
  let!(:other_project_work_package) do
    FactoryBot.create :work_package,
                      project: other_project,
                      type: type,
                      author: user,
                      status: open_status,
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
  let(:general) { ::Components::WorkPackages::TableConfiguration::GraphGeneral.new }

  before do
    login_as user

    dashboard_page.visit!
  end

  context 'with the permission to save queries' do
    it 'can add the widget and see the work packages of the filtered for types' do
      dashboard_page.add_column(3, before_or_after: :before)

      dashboard_page.add_widget(2, 3, "Work packages graph")

      sleep(1)

      filter_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')

      filter_area.expect_to_span(2, 3, 5, 5)
      filter_area.resize_to(6, 5)

      filter_area.expect_to_span(2, 3, 7, 6)

      sleep(1)

      # User has the ability to modify the query

      filter_area.configure_wp_table
      modal.switch_to('Dataset 1')
      filters.expect_filter_count(2)
      filters.add_filter_by('Type', 'is', type.name)
      modal.save

      filter_area.configure_wp_table
      modal.switch_to('General')
      general.set_axis 'Type'
      general.set_type 'Bar'
      modal.save

      sleep(0.5)

      # The whole of the configuration survives a reload
      # as it is persisted in the grid
      # As we cannot check the canvas, we have to rely on the configuration

      visit root_path
      dashboard_page.visit!

      filter_area.configure_wp_table
      modal.switch_to('Dataset 1')

      filters.expect_filter_count(3)

      modal.switch_to('General')
      general.expect_axis 'Type'
      general.expect_type 'Bar'
    end
  end

  context 'without the permission to save queries' do
    let(:permissions) { %i[view_work_packages add_work_packages view_dashboards manage_dashboards] }

    it 'cannot add the widget' do
      dashboard_page.add_column(3, before_or_after: :before)

      dashboard_page.expect_unable_to_add_widget(2, 3, "Work packages graph")
    end
  end
end
