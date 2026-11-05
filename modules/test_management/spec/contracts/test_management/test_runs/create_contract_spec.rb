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
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::TestRuns::CreateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:test_run) { build(:tm_test_run, project:, author: current_user) }
  let(:contract) { described_class.new(test_run, current_user) }

  it_behaves_like "contract is valid"

  context "without add_test_runs" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with an assignee who is not a project member" do
    before { test_run.assigned_to = create(:user) }

    it_behaves_like "contract is invalid", assigned_to: :invalid
  end

  context "with a project member as assignee" do
    before { test_run.assigned_to = current_user }

    it_behaves_like "contract is valid"
  end

  context "with a selected case from another project" do
    before { test_run.selected_case_ids = [create(:tm_test_case).id] }

    it_behaves_like "contract is invalid", selected_case_ids: :invalid
  end

  context "with a filter using a foreign folder" do
    before do
      test_run.selection_mode = "all"
      test_run.filter_options = { "suite_ids" => [create(:tm_suite).id] }
    end

    it_behaves_like "contract is invalid", filter_options: :invalid
  end
end
