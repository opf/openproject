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

RSpec.describe WorkPackages::ProductivityReport do
  shared_let(:open_status) { create(:status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_project] })
  end
  shared_let(:other_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_project] })
  end

  let(:today) { user.today }

  subject(:report) { described_class.new(user:) }

  def assigned_work_package(**attributes)
    create(:work_package, project:, assigned_to: user, status: open_status, **attributes)
  end

  describe "due and overdue work packages" do
    let!(:overdue) { assigned_work_package(due_date: today - 1.day) }
    let!(:due_today) { assigned_work_package(due_date: today) }
    let!(:without_due_date) { assigned_work_package }
    let!(:closed_overdue) { assigned_work_package(status: closed_status, due_date: today - 1.day) }

    before do
      create(:work_package, project:, assigned_to: other_user, status: open_status, due_date: today)
    end

    it "only lists open work packages assigned to the user that are due by the end of the week" do
      expect(report.due_work_packages).to eq([overdue, due_today])
    end

    it "counts overdue work packages" do
      expect(report.overdue_work_packages).to contain_exactly(overdue)
    end

    it "calculates the completion rate over all assigned work packages" do
      expect(report.completion_rate).to eq(25)
    end
  end

  describe "completed work packages" do
    let!(:completed) { assigned_work_package(due_date: today + 1.day) }

    before do
      completed.update!(status: closed_status)
    end

    it "takes the completion date from the journals" do
      expect(report.recently_completed).to contain_exactly(completed)
      expect(report.recently_completed.first.closed_at).to be_within(1.minute).of(Time.current)
    end

    it "counts the completion in the current week" do
      expect(report.completed_this_week_count).to eq(1)
      expect(report.weekly_progress.size).to eq(described_class::WEEKS_OF_HISTORY)
    end

    it "treats completion before the due date as on time" do
      expect(report.on_time_rate).to eq(100)
    end
  end

  describe "#project_breakdown" do
    before do
      assigned_work_package
      assigned_work_package(status: closed_status)
    end

    it "groups the assigned work packages per project" do
      row = report.project_breakdown.first

      expect(row).to have_attributes(project:, total: 2, open: 1, closed: 1, overdue: 0, completion: 50)
    end
  end
end
