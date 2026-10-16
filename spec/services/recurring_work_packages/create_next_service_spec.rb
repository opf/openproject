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

RSpec.describe RecurringWorkPackages::CreateNextService do
  shared_let(:default_status) { create(:default_status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages add_work_packages edit_work_packages add_work_package_notes
                           view_recurring_work_packages manage_recurring_work_packages]
           })
  end

  let(:start_date) { Date.new(2026, 10, 5) }
  let(:due_date) { Date.new(2026, 10, 7) }
  let(:work_package) do
    create(:work_package, project:, type:, author: user, status: default_status, start_date:, due_date:)
  end
  let(:schedule) { { frequency: "weekly", interval: 1, start_date: } }
  let(:series) do
    RecurringWorkPackages::CreateService.new(user:, work_package:).call(schedule).result
  end

  subject(:create_next) { described_class.new(user:, series:).call }

  it "copies the latest occurrence onto the next weekly slot" do
    work_package.update_column(:status_id, closed_status.id)

    expect(create_next).to be_success
    copy = create_next.result

    expect(copy).to have_attributes(subject: work_package.subject,
                                    status: default_status,
                                    start_date: Date.new(2026, 10, 12),
                                    due_date: Date.new(2026, 10, 14),
                                    schedule_manually: true)
    expect(series.occurrences.reload.map { [it.position, it.scheduled_date] })
      .to eq([[1, start_date], [2, Date.new(2026, 10, 12)]])
  end

  it "notes on the source work package that it recurs" do
    series

    expect(work_package.journals.last.notes).to include("Every week on Monday")
  end

  context "when the work package was closed long after its date (overdue)" do
    it "still takes the next planned slot, which is already in the past" do
      travel_to Date.new(2026, 10, 30) do
        expect(create_next.result.start_date).to eq(Date.new(2026, 10, 12))
      end
    end
  end

  context "when the slot is on a non-working day" do
    let(:start_date) { Date.new(2026, 10, 9) }
    let(:due_date) { start_date }
    let(:schedule) { { frequency: "daily", interval: 1, start_date: } }

    before { week_with_saturday_and_sunday_as_weekend }

    it "moves the dates to the next working day but keeps the planned slot" do
      expect(create_next.result).to have_attributes(start_date: Date.new(2026, 10, 12),
                                                    due_date: Date.new(2026, 10, 12))
      expect(series.latest_occurrence.scheduled_date).to eq(Date.new(2026, 10, 10))
    end
  end

  context "for a monthly series starting on the 31st" do
    let(:start_date) { Date.new(2026, 1, 31) }
    let(:due_date) { nil }
    let(:schedule) { { frequency: "monthly", interval: 1, start_date: } }

    it "uses the last day of a shorter month" do
      expect(series.upcoming_dates.first(3))
        .to eq([Date.new(2026, 2, 28), Date.new(2026, 3, 31), Date.new(2026, 4, 30)])
    end
  end

  context "when the work package only has a due date" do
    let(:start_date) { nil }
    let(:due_date) { Date.new(2026, 10, 7) }
    let(:schedule) { { frequency: "weekly", interval: 1, start_date: due_date } }

    it "moves the due date only" do
      expect(create_next.result).to have_attributes(start_date: nil, due_date: Date.new(2026, 10, 14))
    end
  end

  context "when the number of occurrences is reached" do
    let(:schedule) { { frequency: "weekly", interval: 1, start_date:, end_after: "iterations", iterations: 2 } }

    it "creates no third occurrence" do
      described_class.new(user:, series:).call

      expect(create_next).to be_failure
      expect(series).to be_ended
      expect(series.occurrences.count).to eq(2)
    end
  end

  context "when the end date is reached" do
    let(:schedule) do
      { frequency: "weekly", interval: 1, start_date:, end_after: "specific_date", end_date: Date.new(2026, 10, 11) }
    end

    it "creates no occurrence after it" do
      expect(create_next).to be_failure
      expect(series.occurrences.count).to eq(1)
    end
  end

  context "when the target version of the source is closed" do
    let(:version) { create(:version, project:) }

    before do
      work_package.update!(target_versions: [version])
      version.update_column(:status, "closed")
    end

    it "creates the occurrence without the closed version" do
      expect(create_next).to be_success
      expect(create_next.result.reload.target_versions).to be_empty
    end
  end

  context "when the closing user may not add work packages" do
    let(:closer) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }

    it "creates no occurrence and notes the errors on the source work package" do
      series

      expect(described_class.new(user: closer, series:).call).to be_failure
      expect(series.occurrences.count).to eq(1)
      expect(work_package.journals.reload.last)
        .to have_attributes(user: User.system, notes: include("could not be created"))
    end
  end
end
