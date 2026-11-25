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

RSpec.describe TimeEntries::AdjustRemainingWorkService, "integration", type: :model do
  shared_let(:activity) { create(:time_entry_activity) }

  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages edit_work_packages log_own_time edit_own_time_entries]
           })
  end
  let(:setting_enabled) { true }
  let(:project) do
    create(:project,
           enabled_module_names: %i[work_package_tracking costs],
           logged_time_reduces_remaining_work: setting_enabled)
  end
  let(:remaining_hours) { 5.0 }
  let(:work_package) do
    create(:work_package, project:, estimated_hours: 5.0, remaining_hours:)
  end
  let(:logged_hours) { 2.0 }
  let(:create_call) do
    TimeEntries::CreateService
      .new(user:)
      .call(entity: work_package, spent_on: Time.zone.today, hours: logged_hours, activity:)
  end
  let(:time_entry) { create_call.result }

  context "when logging time" do
    it "reduces the remaining work by the logged time" do
      expect(create_call).to be_success
      expect(work_package.reload.remaining_hours).to eq(3.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(120)
    end

    it "derives % complete" do
      create_call

      expect(work_package.reload.done_ratio).to eq(40)
    end

    it "journals the change with the logged time cause" do
      create_call

      expect(work_package.reload.last_journal.cause_type).to eq("logged_time_changed")
    end
  end

  context "when logging more time than remaining work" do
    let(:remaining_hours) { 1.0 }

    it "reduces the remaining work to 0h" do
      create_call

      expect(work_package.reload.remaining_hours).to eq(0.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(60)
    end

    it "keeps the remaining work at 0h when the logged time is reduced to the former remaining work" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(hours: 1.0)

      expect(work_package.reload.remaining_hours).to eq(0.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(60)
    end

    it "gives back what was reduced when the logged time is reduced below the former remaining work" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(hours: 0.5)

      expect(work_package.reload.remaining_hours).to eq(0.5)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(30)
    end
  end

  context "when reducing the logged time" do
    it "gives the difference back to the remaining work" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(hours: 1.0)

      expect(work_package.reload.remaining_hours).to eq(4.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(60)
    end
  end

  context "when increasing the logged time" do
    it "reduces the remaining work by the difference" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(hours: 3.0)

      expect(work_package.reload.remaining_hours).to eq(2.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(180)
    end
  end

  context "when deleting the time entry" do
    it "gives the reduction back to the remaining work" do
      TimeEntries::DeleteService.new(user:, model: time_entry).call

      expect(work_package.reload.remaining_hours).to eq(5.0)
    end

    it "does not raise the remaining work above the work" do
      time_entry
      WorkPackages::UpdateService.new(user:, model: work_package.reload).call(estimated_hours: 4.0)
      expect(work_package.reload.remaining_hours).to eq(2.0)

      TimeEntries::DeleteService.new(user:, model: time_entry.reload).call

      expect(work_package.reload.remaining_hours).to eq(4.0)
    end
  end

  context "when moving the time entry to another work package" do
    let(:other_work_package) do
      create(:work_package, project:, estimated_hours: 8.0, remaining_hours: 8.0)
    end

    it "gives the reduction back to the former work package and reduces the new one" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(entity: other_work_package)

      expect(work_package.reload.remaining_hours).to eq(5.0)
      expect(other_work_package.reload.remaining_hours).to eq(6.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(120)
    end
  end

  context "when tracking time with a timer" do
    let(:create_call) do
      TimeEntries::CreateService
        .new(user:)
        .call(entity: work_package, spent_on: Time.zone.today, ongoing: true, activity:)
    end

    it "keeps the remaining work while the timer runs" do
      expect(create_call).to be_success
      expect(work_package.reload.remaining_hours).to eq(5.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(0)
    end

    it "reduces the remaining work when the timer is stopped" do
      TimeEntries::UpdateService.new(user:, model: time_entry).call(ongoing: false, hours: 1.5)

      expect(work_package.reload.remaining_hours).to eq(3.5)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(90)
    end
  end

  context "when the work package has no remaining work" do
    let(:work_package) { create(:work_package, project:) }

    it "keeps the remaining work empty" do
      create_call

      expect(work_package.reload.remaining_hours).to be_nil
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to eq(0)
    end
  end

  context "when the user is not allowed to edit the work package" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %i[view_work_packages log_own_time edit_own_time_entries]
             })
    end

    it "reduces the remaining work" do
      expect(create_call).to be_success
      expect(work_package.reload.remaining_hours).to eq(3.0)
    end
  end

  context "when the project setting is disabled" do
    let(:setting_enabled) { false }

    it "keeps the remaining work" do
      create_call

      expect(work_package.reload.remaining_hours).to eq(5.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to be_nil
    end

    it "keeps ignoring the time entry once the setting is enabled" do
      time_entry
      project.update!(logged_time_reduces_remaining_work: true)

      TimeEntries::UpdateService.new(user:, model: time_entry.reload).call(hours: 1.0)

      expect(work_package.reload.remaining_hours).to eq(5.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to be_nil
    end
  end

  context "in status-based progress mode", with_settings: { work_package_done_ratio: "status" } do
    it "keeps the remaining work" do
      create_call

      expect(work_package.reload.remaining_hours).to eq(5.0)
      expect(time_entry.reload.remaining_work_reduction_in_minutes).to be_nil
    end
  end
end
