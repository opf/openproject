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

describe 'Subprojects widget on dashboard', type: :feature, js: true do
  let!(:project) do
    FactoryBot.create(:project, parent: parent_project)
  end

  let!(:child_project) do
    FactoryBot.create(:project, parent: project)
  end
  let!(:invisible_child_project) do
    FactoryBot.create(:project, parent: project)
  end
  let!(:grandchild_project) do
    FactoryBot.create(:project, parent: child_project)
  end
  let!(:parent_project) do
    FactoryBot.create(:project)
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end

  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, roles: [role], user: u)
      FactoryBot.create(:member, project: child_project, roles: [role], user: u)
      FactoryBot.create(:member, project: grandchild_project, roles: [role], user: u)
      FactoryBot.create(:member, project: parent_project, roles: [role], user: u)
    end
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard_page.visit!
  end

  it 'can add the widget and see the description in it' do
    dashboard_page.add_widget(1, 1, :within, "Subprojects")

    sleep(0.1)

    subprojects_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within(subprojects_widget.area) do
      expect(page)
        .to have_link(child_project.name)
      expect(page)
        .not_to have_link(grandchild_project.name)
      expect(page)
        .not_to have_link(invisible_child_project.name)
      expect(page)
        .not_to have_link(parent_project.name)
      expect(page)
        .not_to have_link(project.name)
    end
  end
end
