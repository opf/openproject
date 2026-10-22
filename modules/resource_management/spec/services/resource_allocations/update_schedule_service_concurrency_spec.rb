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
require_relative "../../support/resource_allocations/schedule_helpers"

RSpec.describe ResourceAllocations::UpdateScheduleService, "racing a write of the same user's schedule", type: :model do
  include_context "with real database commits"
  include ResourceAllocations::ScheduleHelpers

  let(:monday) { Date.current.next_occurring(:monday) + 1.week }

  let!(:admin) { create(:admin) }
  let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking resource_management]) }
  let!(:other_project) { create(:project, enabled_module_names: %w[work_package_tracking resource_management]) }
  let!(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages],
                                             other_project => %i[view_work_packages] })
  end
  let!(:working_hours) { create(:user_working_hours, user:, valid_from: Date.current - 1.year) }
  let!(:work_package) { create(:work_package, project:) }
  let!(:other_work_package) { create(:work_package, project: other_project) }
  let!(:allocation) do
    create(:resource_allocation, entity: work_package, principal: user,
                                 start_date: monday, end_date: monday + 4.days, allocated_time: 1200)
  end
  let!(:other_allocation) do
    create(:resource_allocation, entity: other_work_package, principal: user,
                                 start_date: monday, end_date: monday + 4.days, allocated_time: 1200)
  end

  let(:recomputation) do
    -> {
      UserWorkingHours::CreateService
        .new(user: admin)
        .call(user:, valid_from: monday, availability_factor: 100,
              monday_hours: 4, tuesday_hours: 4, wednesday_hours: 4, thursday_hours: 4, friday_hours: 4,
              saturday_hours: 0, sunday_hours: 0)
    }
  end

  shared_examples "completing both and keeping the schedule consistent" do
    # rubocop:disable-next RSpec/ExampleLength
    it "completes both and keeps the schedule consistent", retry: 0 do
      recomputation_locked = Concurrent::Event.new
      write_requests_lock = Concurrent::Event.new

      allow(ResourceAllocations::ScheduledEntry).to receive(:lock_schedules_of).and_wrap_original do |lock, users|
        write_requests_lock.set if Thread.current[:schedule_race] == :write
        lock.call(users)
        if Thread.current[:schedule_race] == :recomputation
          recomputation_locked.set
          raise "the write never requested the schedule lock" unless write_requests_lock.wait(10)
        end
      end

      recomputation_thread = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Thread.current[:schedule_race] = :recomputation
          recomputation.call
        rescue StandardError => e
          e
        end
      end
      unless recomputation_locked.wait(10)
        raise "the recomputation never locked the schedule: #{recomputation_thread.join(1)&.value.inspect}"
      end

      write_thread = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Thread.current[:schedule_race] = :write
          write.call
        rescue StandardError => e
          e
        end
      end

      results = [recomputation_thread, write_thread].map { |thread| thread.join(20)&.value }

      expect(results).to all(be_a(ServiceResult).and(be_success))
      expect(stored_schedule(user)).to match_array(computed_schedule(user))
    ensure
      [recomputation_locked, write_requests_lock].compact.each(&:set)
      [recomputation_thread, write_thread].compact.each do |thread|
        thread.join(5) || thread.kill
      end
    end
  end

  context "when an allocation is deleted" do
    let(:write) { -> { ResourceAllocations::DeleteService.new(user: admin, model: allocation).call } }

    it_behaves_like "completing both and keeping the schedule consistent"
  end

  context "when the work package of an allocation is deleted" do
    let(:write) { -> { WorkPackages::DeleteService.new(user: admin, model: work_package).call } }

    it_behaves_like "completing both and keeping the schedule consistent"
  end

  context "when the project of an allocation is deleted" do
    let(:write) { -> { Projects::DeleteService.new(user: admin, model: project).call } }

    it_behaves_like "completing both and keeping the schedule consistent"
  end

  context "when an allocation is created" do
    let(:write) do
      -> {
        ResourceAllocations::CreateService
          .new(user: admin)
          .call(entity: work_package, principal: user, start_date: monday + 1.day, end_date: monday + 3.days,
                allocated_hours: 8)
      }
    end

    it_behaves_like "completing both and keeping the schedule consistent"
  end

  context "when an allocation is updated" do
    let(:write) do
      -> {
        ResourceAllocations::UpdateService
          .new(user: admin, model: allocation)
          .call(start_date: monday + 1.day, allocated_hours: 30)
      }
    end

    it_behaves_like "completing both and keeping the schedule consistent"
  end

  context "when a non-working time is added" do
    let(:write) do
      -> {
        UserNonWorkingTimes::CreateService
          .new(user: admin)
          .call(user:, start_date: monday + 2.days, end_date: monday + 2.days)
      }
    end

    it_behaves_like "completing both and keeping the schedule consistent"
  end
end
