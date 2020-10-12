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

describe 'Read only mode when user lacks edit permission on dashboard', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:dashboard) do
    FactoryBot.create(:dashboard_with_table, project: project)
  end

  let(:permissions) do
    %i[view_work_packages
       add_work_packages
       save_queries
       manage_public_queries
       view_dashboards]
  end

  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end

  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, user: u, roles: [role])
    end
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard_page.visit!
  end

  it 'can not modify the dashboard but can still use it' do
    dashboard_page.expect_unable_to_add_widget(dashboard.row_count, dashboard.column_count, :row)
    dashboard_page.expect_no_help_mode

    table_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    table_widget.expect_not_resizable

    table_widget.expect_not_draggable

    table_widget.expect_not_renameable

    table_widget.expect_no_menu

    within table_widget.area do
      expect(page)
        .to have_content(work_package.subject)
    end
  end
end
