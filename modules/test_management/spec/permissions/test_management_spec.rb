# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Test management permissions" do # rubocop:disable RSpec/DescribeClass
  it "registers the project module and scaffold permissions" do
    permission = OpenProject::AccessControl.permission(:view_test_cases)

    expect(permission.project_module).to eq(:test_management)
    expect(permission.controller_actions)
      .to include("test_management/test_cases/index", "test_management/menus/show")
    expect(permission.permissible_on).to include(:project)
    expect(OpenProject::AccessControl.permission(:manage_test_management)).to be_present
    expect(OpenProject::AccessControl.permission(:add_test_cases)).to be_present
    expect(OpenProject::AccessControl.permission(:manage_test_suites)).to be_present
  end
end
