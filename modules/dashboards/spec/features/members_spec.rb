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

describe 'Members widget on dashboard', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project }
  let!(:other_project) { FactoryBot.create :project }

  let!(:manager_user) do
    FactoryBot.create :user, lastname: "Manager", member_in_project: project, member_through_role: role
  end
  let!(:no_edit_member_user) do
    FactoryBot.create :user, lastname: "No_Edit", member_in_project: project, member_through_role: no_edit_member_role
  end
  let!(:no_view_member_user) do
    FactoryBot.create :user, lastname: "No_View", member_in_project: project, member_through_role: no_view_member_role
  end
  let!(:invisible_user) do
    FactoryBot.create :user, lastname: "Invisible", member_in_project: other_project, member_through_role: role
  end

  let(:no_view_member_role) do
    FactoryBot.create(:role,
                      permissions: %i[manage_dashboards
                                      view_dashboards])
  end
  let(:no_edit_member_role) do
    FactoryBot.create(:role,
                      permissions: %i[manage_dashboards
                                      view_dashboards
                                      view_members])
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i[manage_dashboards
                                      view_dashboards
                                      manage_members
                                      view_members])
  end
  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as manager_user

    dashboard.visit!
  end

  def expect_all_members_visible(area)
    within area do
      expect(page)
        .to have_content role.name
      expect(page)
        .to have_content manager_user.name
      expect(page)
        .to have_content no_edit_member_role
      expect(page)
        .to have_content no_edit_member_user.name
      expect(page)
        .to have_content no_view_member_role
      expect(page)
        .to have_content no_view_member_user.name
    end
  end

  it 'can add the widget and see the members if the permissions suffice' do
    # within top-right area, add an additional widget
    dashboard.add_widget(1, 1, :within, 'Members')

    members_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    expect_all_members_visible(members_area.area)

    expect(page)
      .not_to have_content invisible_user.name

    within members_area.area do
      expect(page)
        .to have_link('Member')
    end

    # A user without edit permission will see the members but cannot add one
    login_as no_edit_member_user

    visit root_path
    dashboard.visit!

    expect_all_members_visible(members_area.area)

    within members_area.area do
      expect(page)
        .to have_no_link('Member')
    end

    # A user without view permission will not see any members
    login_as no_view_member_user

    visit root_path

    dashboard.visit!

    within members_area.area do
      expect(page)
        .to have_no_content manager_user.name

      expect(page)
        .to have_content('No visible members')

      expect(page)
        .to have_no_link('Member')

      expect(page)
        .to have_no_link('View all members')
    end
  end
end
