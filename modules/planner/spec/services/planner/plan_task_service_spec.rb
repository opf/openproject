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

RSpec.describe Planner::PlanTaskService do
  let!(:task_type) { create(:type_task) }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let!(:role) do
    create(:project_role,
           permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR +
             %i[view_work_packages add_work_packages edit_work_packages])
  end
  let(:user) { create(:user) }
  let(:task) { Planner::CreateTaskService.new(user:).call(subject: "Book train", day_part: :morning).result }
  let(:day_part_field) { Planner::DayPartField.find }
  let(:to) { :evening }
  let(:today) { Date.new(2026, 10, 6) }

  subject { described_class.new(user:, work_package: task).call(to:) }

  around { |example| travel_to(Time.zone.parse("2026-10-06 10:00")) { example.run } }

  it "moves the task to another day part today" do
    expect(subject).to be_success, -> { subject.message }
    expect(day_part_field.day_part_of(task.reload)).to eq(:evening)
    expect(task.due_date).to eq(today)
  end

  context "to tomorrow" do
    let(:to) { "tomorrow" }

    it "keeps the day part and plans it for tomorrow" do
      expect(subject).to be_success
      expect(task.reload).to have_attributes(start_date: today + 1, due_date: today + 1)
      expect(day_part_field.day_part_of(task)).to eq(:morning)
    end
  end

  context "when removing it from the plan" do
    let(:to) { "remove" }

    it "clears its dates" do
      expect(subject).to be_success
      expect(task.reload).to have_attributes(start_date: nil, due_date: nil)
    end
  end

  context "when the task is from an earlier day" do
    let(:to) { "today" }

    before { task.update_columns(start_date: today - 2, due_date: today - 2) }

    it "plans it for today in the same day part" do
      expect(subject).to be_success
      expect(task.reload.due_date).to eq(today)
      expect(day_part_field.day_part_of(task)).to eq(:morning)
    end
  end

  context "with an unknown target" do
    let(:to) { "next_year" }

    it "fails" do
      expect(subject).to be_failure
      expect(subject.message).to eq(I18n.t("planner.errors.unknown_target"))
    end
  end
end
