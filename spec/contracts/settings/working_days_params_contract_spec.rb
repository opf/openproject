#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Settings::WorkingDaysParamsContract do
  include_context "ModelContract shared context"
  shared_let(:current_user) { create(:admin) }
  let(:setting) { Setting }
  let(:params) { { working_days: [1] } }
  let(:contract) do
    described_class.new(setting, current_user, params:)
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "without working days" do
    let(:params) { { working_days: [] } }

    include_examples "contract is invalid", base: :working_days_are_missing
  end

  context "with an ApplyWorkingDaysChangeJob already existing",
          with_good_job: WorkPackages::ApplyWorkingDaysChangeJob do
    let(:params) { { working_days: [1, 2, 3] } }

    before do
      WorkPackages::ApplyWorkingDaysChangeJob
        .set(wait: 10.minutes) # GoodJob executes inline job without wait immediately
        .perform_later(user_id: current_user.id,
                       previous_non_working_days: [],
                       previous_working_days: [1, 2, 3, 4])
    end

    include_examples "contract is invalid", base: :previous_working_day_changes_unprocessed
  end
end
