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

RSpec.describe ResourceAllocations::UpdateScheduleService, "consistency with the services", type: :model do
  include ResourceAllocations::ScheduleHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking resource_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  let(:monday) { Date.current.next_occurring(:monday) + 1.week }
  let(:long_work_package) { create(:work_package, project:) }
  let(:short_work_package) { create(:work_package, project:) }

  let!(:long) do
    create(:resource_allocation, entity: long_work_package, principal: user,
                                 start_date: monday, end_date: monday + 11.days, allocated_time: 2400)
  end
  let!(:short) do
    create(:resource_allocation, entity: short_work_package, principal: user,
                                 start_date: monday + 2.days, end_date: monday + 4.days, allocated_time: 1200)
  end
  let!(:late) do
    create(:resource_allocation, entity: long_work_package, principal: user,
                                 start_date: monday + 7.days, end_date: monday + 9.days, allocated_time: 960)
  end
  let!(:other) do
    create(:resource_allocation, entity: create(:work_package, project:, parent: short_work_package),
                                 principal: other_user,
                                 start_date: monday, end_date: monday + 4.days, allocated_time: 1200)
  end
  let!(:non_working_time) do
    create(:user_non_working_time, user:, start_date: monday + 8.days, end_date: monday + 8.days)
  end
  let!(:future_working_hours) do
    create(:user_working_hours, user:, valid_from: monday + 7.days, monday: 240, tuesday: 240)
  end
  let!(:holiday) { create(:non_working_day, date: monday + 10.days) }

  before do
    create(:user_working_hours, user:, valid_from: Date.current - 1.year)
    create(:user_working_hours, user: other_user, valid_from: Date.current - 1.year)

    described_class.new.call(users: [user, other_user], from: nil)
  end

  def expect_consistent_schedules
    expect(stored_schedule(user)).to match_array(computed_schedule(user))
    expect(stored_schedule(other_user)).to match_array(computed_schedule(other_user))
  end

  def expect_success(service_result)
    expect(service_result).to be_success, service_result.errors.full_messages.join(", ")
  end

  def update(allocation, **params)
    expect_success(ResourceAllocations::UpdateService.new(user: admin, model: allocation).call(params))
  end

  it "stores the full schedule after the setup" do
    expect(stored_schedule(user)).not_to be_empty
    expect_consistent_schedules
  end

  it "stays consistent when an allocation is created, spreading overtime back before its start" do
    expect_success(
      ResourceAllocations::CreateService
        .new(user: admin)
        .call(entity: short_work_package, principal: user, start_date: monday + 3.days, end_date: monday + 3.days,
              allocated_time: 720)
    )

    expect_consistent_schedules
    expect(stored_schedule(user)).to include(a_hash_including(allocation_id: long.id, allocated_on: monday,
                                                              overtime_minutes: be_positive))
  end

  it "stays consistent when an allocation starts earlier" do
    update(late, start_date: monday + 1.day)

    expect_consistent_schedules
  end

  it "stays consistent when an allocation starts later" do
    update(short, start_date: monday + 4.days, end_date: monday + 8.days)

    expect_consistent_schedules
  end

  it "stays consistent when the allocated time grows into overtime" do
    update(late, allocated_time: 2400)

    expect_consistent_schedules
    expect(stored_schedule(user)).to include(a_hash_including(allocation_id: long.id, allocated_on: monday,
                                                              overtime_minutes: be_positive))
  end

  it "stays consistent when an allocation is canceled" do
    update(short, state: "canceled")

    expect_consistent_schedules
  end

  it "stays consistent when an allocation moves to another user" do
    update(short, principal: other_user)

    expect_consistent_schedules
    expect(stored_schedule(other_user).pluck(:allocation_id)).to include(short.id)
  end

  it "stays consistent when an allocation is deleted" do
    expect_success(ResourceAllocations::DeleteService.new(user: admin, model: short).call)

    expect_consistent_schedules
  end

  it "stays consistent when a work package with allocations on it and its children is deleted" do
    expect_success(WorkPackages::DeleteService.new(user: admin, model: short_work_package).call)

    expect_consistent_schedules
    expect(stored_schedule(other_user)).to be_empty
  end

  it "stays consistent when working hours are added" do
    expect_success(
      UserWorkingHours::CreateService
        .new(user: admin)
        .call(user:, valid_from: monday + 3.days,
              monday_hours: 2, tuesday_hours: 0, wednesday_hours: 2, thursday_hours: 2, friday_hours: 0,
              saturday_hours: 0, sunday_hours: 0, availability_factor: 100)
    )

    expect_consistent_schedules
  end

  it "stays consistent when working hours move earlier" do
    expect_success(
      UserWorkingHours::UpdateService
        .new(user: admin, model: future_working_hours)
        .call(valid_from: monday + 1.day)
    )

    expect_consistent_schedules
  end

  it "stays consistent when working hours are deleted" do
    expect_success(UserWorkingHours::DeleteService.new(user: admin, model: future_working_hours).call)

    expect_consistent_schedules
  end

  it "stays consistent when a non-working time is added" do
    expect_success(
      UserNonWorkingTimes::CreateService
        .new(user: admin)
        .call(user:, start_date: monday + 3.days, end_date: monday + 4.days)
    )

    expect_consistent_schedules
  end

  it "stays consistent when a non-working time moves earlier" do
    expect_success(
      UserNonWorkingTimes::UpdateService
        .new(user: admin, model: non_working_time)
        .call(start_date: monday + 2.days)
    )

    expect_consistent_schedules
  end

  it "stays consistent when a non-working time is deleted" do
    expect_success(UserNonWorkingTimes::DeleteService.new(user: admin, model: non_working_time).call)

    expect_consistent_schedules
  end

  it "stays consistent when global non-working days change" do
    expect_success(
      Settings::WorkingDaysAndHoursUpdateService
        .new(user: admin)
        .call(working_days: Setting.working_days, hours_per_day: Setting.hours_per_day.to_s,
              non_working_days: [{ "name" => "Added", "date" => (monday + 1.day).iso8601 },
                                 { "id" => holiday.id, "_destroy" => true }])
    )
    perform_enqueued_jobs(only: ResourceAllocations::RescheduleForNonWorkingDaysJob)

    expect_consistent_schedules
  end
end
