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

RSpec.describe Settings::WorkingDaysAndHoursParamsContract do
  include_context "ModelContract shared context"
  shared_let(:current_user) { create(:admin) }
  let(:setting) { Setting }
  let(:params) { { working_days: [1], hours_per_day: 8, days_per_week: 5, days_per_month: 20 } }
  let(:contract) do
    described_class.new(setting, current_user, params:)
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  %i[working_days hours_per_day days_per_week days_per_month].each do |attribute|
    context "without #{attribute}" do
      let(:params) { { working_days: [1], hours_per_day: 8, days_per_week: 5, days_per_month: 20 }.except(attribute) }

      include_examples "contract is invalid", base: :"#{attribute}_are_missing"
    end
  end

  context "with an ApplyWorkingDaysChangeJob already existing",
          with_good_job: WorkPackages::ApplyWorkingDaysChangeJob do
    let(:params) { { working_days: [1, 2, 3], hours_per_day: 8, days_per_week: 5, days_per_month: 20 } }

    before do
      WorkPackages::ApplyWorkingDaysChangeJob
        .set(wait: 10.minutes) # GoodJob executes inline job without wait immediately
        .perform_later(user_id: current_user.id,
                       previous_non_working_days: [],
                       previous_working_days: [1, 2, 3, 4])
    end

    include_examples "contract is invalid", base: :previous_working_day_changes_unprocessed
  end

  context "when days_per_week and days_per_month aren't consistent with each other" do
    # There are 4 weeks per month on average, so 10 days per month in non-sensical given 5 days per week
    let(:params) { { working_days: [1], hours_per_day: 8, days_per_week: 5, days_per_month: 10 } }

    include_examples "contract is invalid", base: :days_per_week_and_days_per_month_are_inconsistent
  end

  describe "0 durations" do
    context "when hours_per_day is 0" do
      let(:params) { { working_days: [1], hours_per_day: 0, days_per_week: 5, days_per_month: 20 } }

      include_examples "contract is invalid", base: :durations_are_not_positive_numbers
    end

    # These two are correlated. Making only one of them 0 will also
    # add the "incosistent" error tested for above.
    context "when days_per_week or days_per_month is 0" do
      let(:params) { { working_days: [1], hours_per_day: 8, days_per_week: 0, days_per_month: 0 } }

      include_examples "contract is invalid", base: :durations_are_not_positive_numbers
    end

    context "when all durations are 0" do
      let(:params) { { working_days: [1], hours_per_day: 0, days_per_week: 0, days_per_month: 0 } }

      include_examples "contract is invalid", base: :durations_are_not_positive_numbers
    end
  end

  describe "Text durations" do
    let(:params) { { working_days: [1], hours_per_day: "blah", days_per_week: "5", days_per_month: "20" } }

    include_examples "contract is invalid", base: :durations_are_not_positive_numbers
  end

  describe "Negative durations" do
    let(:params) { { working_days: [1], hours_per_day: -2, days_per_week: -5, days_per_month: -20 } }

    include_examples "contract is invalid", base: :durations_are_not_positive_numbers
  end

  describe "Out-of-bounds durations" do
    context "when hours_per_day is greater than 24" do
      let(:params) { { working_days: [1], hours_per_day: 25, days_per_week: 5, days_per_month: 20 } }

      include_examples "contract is invalid", base: :hours_per_day_is_out_of_bounds
    end

    context "when days_per_week is greater than 7 and days_per_month is greater than 31" do
      let(:params) { { working_days: [1], hours_per_day: 8, days_per_week: 8, days_per_month: 32 } }

      include_examples "contract is invalid", base: %i[days_per_week_is_out_of_bounds days_per_month_is_out_of_bounds]
    end
  end
end
