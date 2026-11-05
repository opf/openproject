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

RSpec.describe TestManagement::TestRuns::DeleteService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs delete_test_runs]
           })
  end
  let(:test_run) { create(:tm_test_run, project:) }

  it "destroys the test run" do
    create(:tm_test_run_case, test_run:)
    id = test_run.id

    result = described_class.new(user:, model: test_run).call

    expect(result).to be_success
    expect(TestManagement::TestRun.find_by(id:)).to be_nil
  end

  it "refuses without delete_test_runs" do
    viewer = create(:user, member_with_permissions: {
                      project => %i[view_test_cases view_test_runs]
                    })

    result = described_class.new(user: viewer, model: test_run).call

    expect(result).to be_failure
    expect(TestManagement::TestRun.find_by(id: test_run.id)).to be_present
  end
end
