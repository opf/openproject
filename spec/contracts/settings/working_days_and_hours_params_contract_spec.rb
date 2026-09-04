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
  let(:params) { { working_days: [1], hours_per_day: 8 } }
  let(:contract) do
    described_class.new(setting, current_user, params:)
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  %i[working_days hours_per_day].each do |attribute|
    context "without #{attribute}" do
      let(:params) { { working_days: [1], hours_per_day: 8 }.except(attribute) }

      include_examples "contract is invalid", base: :"#{attribute}_are_missing"
    end
  end

  [
    Projects::Phases::ApplyWorkingDaysChangeJob,
    WorkPackages::ApplyWorkingDaysChangeJob
  ].each do |job_class|
    context "with an #{job_class} already existing", with_good_job: job_class do
      let(:params) { { working_days: [1, 2, 3], hours_per_day: 8 } }

      before do
        job_class
          .set(wait: 10.minutes) # GoodJob executes inline job without wait immediately
          .perform_later(user_id: current_user.id,
                         previous_non_working_days: [],
                         previous_working_days: [1, 2, 3, 4])
      end

      include_examples "contract is invalid", base: :previous_working_day_changes_unprocessed
    end

    # Regression OP-19861: a still running job must also block further working-days
    # changes. Previously check_concurrency used advisory_unlocked and allowed a second
    # save while ApplyWorkingDaysChangeJob was still running.
    # GoodJob then aborted enqueue of the follow-up job, leaving new non-working days unapplied.
    context "with an #{job_class} currently performing", with_good_job: job_class do
      let(:params) { { working_days: [1, 2, 3], hours_per_day: 8 } }

      around do |example|
        job_class
          .set(wait: 10.minutes)
          .perform_later(user_id: current_user.id,
                         previous_non_working_days: [],
                         previous_working_days: [1, 2, 3, 4])

        good_job = GoodJob::Job.order(:created_at).last
        good_job.update_columns(performed_at: Time.current)

        lock_held = Concurrent::Event.new
        release_lock = Concurrent::Event.new

        thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            good_job.advisory_lock!
            lock_held.set
            release_lock.wait(5)
            good_job.advisory_unlock!
          end
        end

        raise "failed to acquire advisory lock on job" unless lock_held.wait(5)

        example.run
      ensure
        release_lock&.set
        thread&.join(5)
      end

      include_examples "contract is invalid", base: :previous_working_day_changes_unprocessed
    end
  end

  describe "0 durations" do
    context "when hours_per_day is 0" do
      let(:params) { { working_days: [1], hours_per_day: 0 } }

      include_examples "contract is invalid", base: :durations_are_not_positive_numbers
    end
  end

  describe "Text durations" do
    let(:params) { { working_days: [1], hours_per_day: "blah" } }

    include_examples "contract is invalid", base: :durations_are_not_positive_numbers
  end

  describe "Negative durations" do
    let(:params) { { working_days: [1], hours_per_day: -2 } }

    include_examples "contract is invalid", base: :durations_are_not_positive_numbers
  end

  describe "Out-of-bounds durations" do
    context "when hours_per_day is greater than 24" do
      let(:params) { { working_days: [1], hours_per_day: 25 } }

      include_examples "contract is invalid", base: :hours_per_day_is_out_of_bounds
    end
  end
end
