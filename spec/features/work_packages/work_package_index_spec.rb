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

RSpec.feature 'Work package index view' do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[work_package_tracking]) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end

  scenario 'is reachable by clicking the sidebar menu item', js: true do
    visit project_path(project)

    within('#content') do
      expect(page).to have_content('Overview')
    end

    within('#main-menu') do
      click_link 'Work package'
    end

    expect(current_path).to eql("/projects/#{project.identifier}/work_packages")
    within('#content') do
      wp_table.expect_title('All open', editable: true)
      expect(page).to have_content('No work packages to display')
    end
  end
end
