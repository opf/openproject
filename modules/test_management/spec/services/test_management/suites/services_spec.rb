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

RSpec.describe "Folder services" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_suites] }) }

  it "creates a subfolder" do
    parent = create(:tm_suite, project:)
    result = TestManagement::Suites::CreateService.new(user:).call(name: "Child", parent_id: parent.id, project:)

    expect(result).to be_success
    expect(result.result.parent).to eq(parent)
  end

  it "renames a folder" do
    suite = create(:tm_suite, project:)
    result = TestManagement::Suites::UpdateService.new(user:, model: suite).call(name: "Renamed")

    expect(result).to be_success
    expect(suite.reload.name).to eq("Renamed")
  end

  it "deletes a folder" do
    suite = create(:tm_suite, project:)
    expect(TestManagement::Suites::DeleteService.new(user:, model: suite).call).to be_success
    expect(TestManagement::Suite.where(id: suite.id)).to be_empty
  end

  it "refuses without manage_test_suites" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })
    result = TestManagement::Suites::CreateService.new(user: viewer).call(name: "X", project:)

    expect(result).not_to be_success
  end
end
