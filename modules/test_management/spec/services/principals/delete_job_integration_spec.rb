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

RSpec.describe Principals::DeleteJob, "Test Management", type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:deleted_user) { create(:deleted_user) }

  let(:principal) { create(:user) }
  let(:project) { create(:project) }

  it "rewrites attribution references" do
    test_case = create(:tm_test_case, project:, author: principal, assigned_to: principal, updated_by: principal)
    run = create(:tm_test_run, project:, author: principal, assigned_to: principal, finished_by: principal)
    run_case = create(:tm_test_run_case, test_run: run, assigned_to: principal)
    result = create(:tm_test_result, run_case:, user: principal)
    import = create(:tm_automation_import, test_run: run, project:, user: principal)
    connection = create(:tm_ci_connection, project:, created_by: principal)
    iteration = create(:tm_test_run_iteration, test_run: run, created_by: principal)

    job

    expect(test_case.reload).to have_attributes(
      author: deleted_user,
      assigned_to: deleted_user,
      updated_by: deleted_user
    )
    expect(run.reload).to have_attributes(
      author: deleted_user,
      assigned_to: deleted_user,
      finished_by: deleted_user
    )
    expect(run_case.reload.assigned_to).to eq(deleted_user)
    expect(result.reload.user).to eq(deleted_user)
    expect(import.reload.user).to eq(deleted_user)
    expect(connection.reload.created_by).to eq(deleted_user)
    expect(iteration.reload.created_by).to eq(deleted_user)
  end
end
