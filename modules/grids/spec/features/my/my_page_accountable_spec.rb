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

describe 'Accountable widget on my page', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:other_project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:accountable_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user,
                      responsible: user
  end
  let!(:accountable_by_other_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user,
                      responsible: other_user
  end
  let!(:accountable_but_invisible_work_package) do
    FactoryBot.create :work_package,
                      project: other_project,
                      type: type,
                      author: user,
                      responsible: user
  end
  let(:other_user) do
    FactoryBot.create(:user)
  end

  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages add_work_packages]) }

  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  it 'can add the widget and see the work packages the user is accountable for' do
    my_page.add_column(3, before_or_after: :before)

    my_page.add_widget(2, 3, "Work packages I am accountable for")

    sleep(0.2)

    accountable_area = Components::Grids::GridArea.new('.grid--area', text: "Work packages I am accountable for")
    created_area = Components::Grids::GridArea.new('.grid--area', text: "Work packages created by me")

    accountable_area.expect_to_span(2, 3, 5, 4)
    accountable_area.resize_to(6, 4)

    accountable_area.expect_to_span(2, 3, 7, 5)
    # enlarging the accountable area will have moved the created area down
    created_area.expect_to_span(7, 4, 13, 6)

    expect(accountable_area.area)
      .to have_selector('.subject', text: accountable_work_package.subject)

    expect(accountable_area.area)
      .to have_no_selector('.subject', text: accountable_by_other_work_package.subject)

    expect(accountable_area.area)
      .to have_no_selector('.subject', text: accountable_but_invisible_work_package.subject)
  end
end
