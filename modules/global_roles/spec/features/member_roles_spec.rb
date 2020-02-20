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

describe 'Global role: Unchanged Member Roles', type: :feature, js: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create :project }
  let!(:role) { FactoryBot.create(:role, name: 'MemberRole1') }
  let!(:global_role) { FactoryBot.create(:global_role, name: 'GlobalRole1') }

  let(:members) { ::Pages::Members.new project.identifier }

  before do
    login_as(admin)
  end

  scenario 'Global Rights Modules do not exist as Project -> Settings -> Modules' do
    # Scenario: Global Roles should not be displayed as assignable project roles
    # Given there is 1 project with the following:
    # | Name       | projectname |
    # | Identifier | projectid   |
    #   And there is a global role "GlobalRole1"
    # And there is a role "MemberRole1"
    # And I am already admin
    # When I go to the members page of the project "projectid"
    visit project_members_path(project)
    # And I click "Add member"
    members.open_new_member!

    # Then I should see "MemberRole1" within "#member_role_ids"
    members.expect_role 'MemberRole1'

    # Then I should not see "GlobalRole1" within "#member_role_ids"
    members.expect_role 'GlobalRole1', present: false
  end
end
