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

RSpec.describe TestManagement::TestCases::DeleteService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases delete_test_cases] }) }
  let(:test_case) { create(:tm_test_case, :with_steps, project:) }

  it "deletes the test case with its steps" do
    run_case = create(:tm_test_run_case, test_case:, test_run: create(:tm_test_run, project:))

    result = described_class.new(user:, model: test_case).call

    expect(result).to be_success
    expect(TestManagement::TestCase.exists?(test_case.id)).to be(false)
    expect(TestManagement::TestStep.where(test_case_id: test_case.id)).to be_empty
    expect(TestManagement::TestRunCase.exists?(run_case.id)).to be(false)
  end

  it "is refused without delete_test_cases" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })

    expect(described_class.new(user: viewer, model: test_case).call).to be_failure
    expect(TestManagement::TestCase.exists?(test_case.id)).to be(true)
  end
end
