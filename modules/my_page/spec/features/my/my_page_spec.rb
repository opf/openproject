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

describe 'My page', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:created_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user
  end
  let!(:assigned_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      assigned_to: user
  end

  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages add_work_packages])
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  it 'renders the default view, allows altering and saving' do
    assigned_area = Components::Grids::GridArea.new('.grid--area', text: 'Work packages assigned to me')
    created_area = Components::Grids::GridArea.new('.grid--area', text: 'Work packages created by me')

    assigned_area.expect_to_exist
    created_area.expect_to_exist
    assigned_area.expect_to_span(1, 1, 7, 3)
    created_area.expect_to_span(1, 3, 7, 5)

    # The widgets load their respective contents
    expect(page)
      .to have_content(created_work_package.subject)
    expect(page)
      .to have_content(assigned_work_package.subject)

    my_page.add_row(1)

    # within top-right area, add an additional widget
    my_page.add_widget(1, 1, 'Calendar')

    calendar_area = Components::Grids::GridArea.new('.grid--area', text: 'Calendar')
    calendar_area.expect_to_span(1, 1, 2, 3)

    calendar_area.resize_to(2, 4)

    # Resizing leads to the calendar area now spanning a larger area
    calendar_area.expect_to_span(1, 1, 3, 5)
    # Because of the added column, and the resizing the other widgets have moved down
    assigned_area.expect_to_span(3, 1, 9, 3)
    created_area.expect_to_span(3, 3, 9, 5)

    my_page.add_column(4, before_or_after: :after)
    my_page.add_column(5, before_or_after: :after)
    my_page.add_widget(1, 5, 'Work packages watched by me')

    watched_area = Components::Grids::GridArea.new('.grid--area', text: 'Work packages watched by me')
    watched_area.expect_to_exist

    watched_area.resize_to(3, 6)

    # Reloading kept the user's values
    visit home_path
    my_page.visit!

    assigned_area.expect_to_exist
    created_area.expect_to_exist
    calendar_area.expect_to_exist
    watched_area.expect_to_exist
    calendar_area.expect_to_span(1, 1, 3, 5)
    assigned_area.expect_to_span(3, 1, 9, 3)
    created_area.expect_to_span(3, 3, 9, 5)
    watched_area.expect_to_span(1, 5, 4, 7)

    # Disabling the following as it leads to false positives on travis only

    # # dragging makes room for the dragged widget which means
    # # that widgets that have been there are moved down
    # watched_area.drag_to(1, 3)
    # watched_area.expect_to_span(1, 3, 4, 5)
    # calendar_area.expect_to_span(4, 1, 6, 5)
    # assigned_area.expect_to_span(6, 1, 12, 3)
    # created_area.expect_to_span(6, 3, 12, 5)

    # calendar_area.drag_to(3, 4)
    # # reduces the size of calendar as the widget would otherwise not fit
    # calendar_area.expect_to_span(3, 4, 5, 7)
    # watched_area.expect_to_span(5, 3, 8, 5)
    # assigned_area.expect_to_span(6, 1, 12, 3)
    # created_area.expect_to_span(8, 3, 14, 5)
  end
end
