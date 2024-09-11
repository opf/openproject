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

RSpec.shared_examples_for "time entry contract" do
  let(:current_user) { build_stubbed(:user) }
  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project: time_entry_project) if time_entry_project
    end
  end

  let(:other_user) { build_stubbed(:user) }
  let(:time_entry_work_package) do
    build_stubbed(:work_package,
                  project: time_entry_project)
  end
  let(:time_entry_project) { build_stubbed(:project) }
  let(:time_entry_user) { current_user }
  let(:time_entry_activity) do
    build_stubbed(:time_entry_activity)
  end
  let(:time_entry_activity_active) { true }
  let(:time_entry_spent_on) { Time.zone.today }
  let(:time_entry_hours) { 5 }
  let(:time_entry_comments) { "A comment" }
  let(:work_package_visible) { true }
  let(:time_entry_day_sum) { 5 }
  let(:activities_scope) do
    scope = class_double(TimeEntryActivity)

    if time_entry_activity
      allow(scope)
        .to receive(:exists?)
        .with(time_entry_activity.id)
        .and_return(time_entry_activity_active)
    end

    scope
  end

  before do
    if time_entry_work_package
      allow(time_entry_work_package)
        .to receive(:visible?)
        .with(current_user)
        .and_return(work_package_visible)
    end

    allow(TimeEntryActivity)
      .to receive(:active_in_project)
      .and_return(TimeEntryActivity.none)

    of_user_and_day_scope = instance_double(ActiveRecord::Relation)

    allow(TimeEntry)
      .to receive(:of_user_and_day)
      .and_return(TimeEntry.none)

    allow(TimeEntry)
      .to receive(:of_user_and_day)
      .with(time_entry.user, time_entry_spent_on, excluding: time_entry)
      .and_return(of_user_and_day_scope)

    allow(of_user_and_day_scope)
      .to receive(:sum)
      .with(:hours)
      .and_return(time_entry_day_sum)

    allow(TimeEntryActivity)
      .to receive(:active_in_project)
      .with(time_entry_project)
      .and_return(activities_scope)
  end

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples "is valid" do
    it "is valid" do
      expect_valid(true)
    end
  end

  it_behaves_like "is valid"

  context "when the work_package is within a different project than the provided project" do
    let(:time_entry_work_package) { build_stubbed(:work_package) }

    it "is invalid" do
      expect_valid(false, work_package_id: %i(invalid))
    end
  end

  context "when the work_package is nil" do
    let(:time_entry_work_package) { nil }

    it_behaves_like "is valid"
  end

  context "when the project is nil" do
    let(:time_entry_project) { nil }

    it "is invalid" do
      expect_valid(false, project_id: %i(invalid blank))
    end
  end

  context "when activity is nil" do
    let(:time_entry_activity) { nil }

    it_behaves_like "is valid"
  end

  context "if the activity is disabled in the project" do
    let(:time_entry_activity_active) { false }

    it "is invalid" do
      expect_valid(false, activity_id: %i(inclusion))
    end
  end

  context "when spent_on is nil" do
    let(:time_entry_spent_on) { nil }

    it "is invalid" do
      expect_valid(false, spent_on: %i(blank))
    end
  end

  context "when spent_on is outside the year limits to prevent overflow in postgres" do
    let(:time_entry_spent_on) { Date.new(10000) }

    it "is invalid" do
      expect_valid(false, spent_on: %i(date_before_or_equal_to))
    end
  end

  context "when spent_on is in the future" do
    let(:time_entry_spent_on) { Date.new(9999) }

    it "is valid" do
      expect_valid(true)
    end
  end

  context "when spent_on is today" do
    let(:time_entry_spent_on) { Time.zone.today }

    it "is valid" do
      expect_valid(true)
    end
  end

  context "when spent_on is in the past" do
    let(:time_entry_spent_on) { Time.zone.yesterday }

    it "is valid" do
      expect_valid(true)
    end
  end

  context "when hours is nil" do
    let(:time_entry_hours) { nil }

    it "is invalid" do
      expect_valid(false, hours: %i(blank))
    end
  end

  context "when hours is negative" do
    let(:time_entry_hours) { -1 }

    it "is invalid" do
      expect_valid(false, hours: %i(invalid))
    end
  end

  context "when comment is nil" do
    let(:time_entry_comments) { nil }

    it_behaves_like "is valid"
  end

  context "if more than 24 hours are booked for a day" do
    let(:time_entry_day_sum) { 24 - time_entry_hours + 1 }

    it "is valid" do
      expect_valid(true)
    end
  end

  describe "assignable_activities" do
    context "if no project is set" do
      let(:time_entry_project) { nil }

      it "is empty" do
        expect(contract.assignable_activities)
          .to be_empty
      end
    end

    context "if a project is set" do
      it "returns all activities active in the project" do
        expect(contract.assignable_activities)
          .to eql activities_scope
      end
    end
  end

  describe "assignable_versions" do
    let(:project_versions) { [instance_double(Version)] }
    let(:wp_versions) { [instance_double(Version)] }

    before do
      if time_entry_project
        allow(time_entry_project)
          .to receive(:assignable_versions)
          .and_return project_versions
      end

      if time_entry_work_package
        allow(time_entry_work_package)
          .to receive(:assignable_versions)
          .and_return wp_versions
      end
    end

    context "if no project and no work package is set" do
      let(:time_entry_project) { nil }
      let(:time_entry_work_package) { nil }

      it "is empty" do
        expect(contract.assignable_versions)
          .to be_empty
      end
    end

    context "if a project is set but no work package" do
      let(:time_entry_work_package) { nil }

      it "returns assignable_versions of the project" do
        expect(contract.assignable_versions)
          .to eql project_versions
      end
    end

    context "if a work_package is set but no project" do
      let(:time_entry_project) { nil }

      it "returns assignable_versions of the project" do
        expect(contract.assignable_versions)
          .to eql wp_versions
      end
    end

    context "if both project and work_package are set" do
      it "returns assignable_versions of the project" do
        expect(contract.assignable_versions)
          .to eql wp_versions
      end
    end
  end
end
