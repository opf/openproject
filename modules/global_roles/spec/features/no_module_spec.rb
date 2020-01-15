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

require_relative '../spec_helper'

describe 'Global role: No module', type: :feature, js: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create :project }
  let!(:role) { FactoryBot.create(:role) }

  before do
    login_as(admin)
  end

  scenario 'Global Rights Modules do not exist as Project -> Settings -> Modules' do
    # Scenario:
    # Given there is the global permission "glob_test" of the module "global"
    mock_global_permissions [['global_perm1', project_module: :global]]

    # And there is 1 project with the following:
    # | name       | test |
    # | identifier | test |
    #   And I am already admin
    # When I go to the modules tab of the settings page for the project "test"
    #                                                     Then I should not see "Global"
    visit settings_modules_project_path(project)

    expect(page).to have_text 'Activity'
    expect(page).to have_no_text 'Foo'
  end
end
