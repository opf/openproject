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
require 'support/pages/custom_fields'

describe 'types', js: true do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i(edit_project manage_types add_work_packages view_work_packages)
  end
  let!(:active_type) { FactoryBot.create(:type) }
  let!(:type) { FactoryBot.create(:type) }
  let!(:project) { FactoryBot.create(:project, types: [active_type]) }
  let(:project_settings_page) { Pages::Projects::Settings.new(project) }
  let(:work_packages_page) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end

  it 'is only visible in the project if it has been activated' do
    # the currently active types are available for work package creation
    work_packages_page.visit!

    work_packages_page.expect_type_available_for_create(active_type)
    work_packages_page.expect_type_not_available_for_create(type)

    project_settings_page.visit_tab!('types')

    expect(page)
      .to have_unchecked_field(type.name)
    expect(page)
      .to have_checked_field(active_type.name)

    # switch enabled types
    check(type.name)
    uncheck(active_type.name)

    project_settings_page.save!

    expect(page)
      .to have_checked_field(type.name)
    expect(page)
      .to have_unchecked_field(active_type.name)

    # the newly activated types are available for work package creation
    # disabled ones are not
    work_packages_page.visit!

    work_packages_page.expect_type_available_for_create(type)
    work_packages_page.expect_type_not_available_for_create(active_type)
  end
end
