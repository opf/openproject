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

RSpec.describe TestManagement::TestRuns::UpdateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:test_run) { create(:tm_test_run, project:) }
  let(:contract) { described_class.new(test_run, current_user) }

  before { test_run.name = "Renamed" }

  it_behaves_like "contract is valid"

  context "when the run is completed" do
    let(:test_run) { create(:tm_test_run, :completed, project:) }

    it_behaves_like "contract is invalid", base: :tm_run_finished
  end

  context "when the run is cancelled" do
    let(:test_run) { create(:tm_test_run, :cancelled, project:) }

    it_behaves_like "contract is invalid", base: :tm_run_finished
  end
end
