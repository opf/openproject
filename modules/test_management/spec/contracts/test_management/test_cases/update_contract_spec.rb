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

RSpec.describe TestManagement::TestCases::UpdateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:test_case) { create(:tm_test_case, project:, status: "draft") }
  let(:contract) { described_class.new(test_case, current_user) }

  context "with edit_test_cases" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] }) }

    before { test_case.title = "New title" }

    it_behaves_like "contract is valid"
  end

  context "with a folder of another project" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] }) }

    before { test_case.suite = create(:tm_suite) }

    it_behaves_like "contract is invalid", suite_id: :invalid
  end

  context "without edit_test_cases" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

    before { test_case.status = "ready" }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end
end
