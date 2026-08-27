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

RSpec.describe SprintWorkPackageBreakdown do
  # Backdates a journalized attribute change, mirroring the helper in burndown_spec.rb
  def set_attribute_journalized(work_package, attribute, value, changed_at)
    work_package.reload
    work_package.send(attribute, value)
    work_package.save!
    if work_package.journals.many?
      work_package.journals[-2].update_columns(validity_period: work_package.journals[-2].created_at...changed_at)
    end
    work_package.journals[-1].update_columns(created_at: changed_at, updated_at: changed_at,
                                             validity_period: changed_at..Float::INFINITY)
  end

  def backdate_creation_journal(work_package)
    work_package.last_journal.update_columns(
      created_at: work_package.created_at,
      updated_at: work_package.created_at,
      validity_period: work_package.created_at..Float::INFINITY
    )
  end

  let(:project) { create(:project) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:type_feature) { create(:type_feature) }
  let(:issue_open) { create(:status, name: "Open", is_default: true) }
  let(:issue_closed) { create(:status, name: "Closed", is_closed: true) }

  current_user { create(:user, member_with_roles: { project => role }) }

  subject(:breakdown) { described_class.new(sprint:, project:) }

  around do |example|
    travel_to(Time.zone.local(2024, 6, 20, 12, 0)) { example.run }
  end

  describe "#reference_start and #reference_finish" do
    context "when the sprint is still ongoing" do
      let(:sprint) do
        create(:sprint, project:,
                        start_date: Time.zone.today - 10.days,
                        finish_date: Time.zone.today + 4.days,
                        started_at: 10.days.ago)
      end

      it "keeps reference_start at the actual start timestamp" do
        expect(breakdown.reference_start).to eq(Timestamp.new(sprint.started_at))
      end

      it "clips reference_finish to now" do
        expect(breakdown.reference_finish).to eq(Timestamp.now)
      end
    end

    context "when the sprint was completed before its finish date" do
      let(:sprint) do
        create(:sprint, project:,
                        start_date: Time.zone.today - 20.days,
                        finish_date: Time.zone.today + 5.days,
                        started_at: 20.days.ago,
                        completed_at: 1.day.ago)
      end

      it "keeps reference_finish at the sprint completion timestamp rather than current time" do
        expect(breakdown.reference_finish).to eq(Timestamp.new(sprint.completed_at))
      end
    end

    context "when the sprint was completed after its finish date" do
      let(:sprint) do
        create(:sprint, project:,
                        start_date: Time.zone.today - 20.days,
                        finish_date: Time.zone.today - 5.days,
                        started_at: 20.days.ago,
                        completed_at: 1.day.ago)
      end

      it "keeps reference_finish at the sprint completion timestamp rather than current time" do
        expect(breakdown.reference_finish).to eq(Timestamp.new(sprint.completed_at))
      end
    end

    context "when the sprint has not started yet" do
      let(:sprint) do
        create(:sprint, project:, start_date: Time.zone.today + 3.days, finish_date: Time.zone.today + 10.days)
      end

      it "has nil timestamps" do
        expect(breakdown.reference_start).to be_nil
        expect(breakdown.reference_finish).to be_nil
      end
    end
  end

  describe "a sprint that has not started" do
    let(:sprint) do
      create(:sprint, project:, start_date: Time.zone.today + 3.days, finish_date: Time.zone.today + 10.days)
    end

    let!(:planned_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 5)
    end

    it "reports empty breakdown" do
      expect(breakdown.initially_planned).to have_attributes(work_package_count: 0, story_points: 0)
      expect(breakdown.completed).to have_attributes(work_package_count: 0, story_points: 0)
      expect(breakdown.unfinished).to have_attributes(work_package_count: 0, story_points: 0)
      expect(breakdown.changed_after_start)
        .to have_attributes(added_count: 0, removed_count: 0, added_story_points: 0, removed_story_points: 0)
      expect(breakdown.added_after_start_ids).to be_empty
      expect(breakdown.removed_after_start_ids).to be_empty
    end
  end

  describe "#initially_planned, #completed and #unfinished" do
    let(:sprint) do
      create(:sprint, project:,
                      start_date: Time.zone.today - 10.days,
                      finish_date: Time.zone.today + 4.days,
                      started_at: 10.days.ago)
    end

    let!(:open_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 5,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    let!(:closed_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_closed, story_points: 3,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    let!(:other_project_work_package) do
      create(:work_package, type: type_feature, status: issue_open, story_points: 100,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    before do
      [open_work_package, closed_work_package, other_project_work_package].each { |wp| backdate_creation_journal(wp) }
    end

    it "counts the work packages assigned to the sprint at the reference date, excluding other projects" do
      expect(breakdown.initially_planned.work_package_count).to eq(2)
      expect(breakdown.initially_planned.story_points).to eq(8)
    end

    it "splits completed vs. unfinished by the project's done statuses" do
      expect(breakdown.completed.work_package_count).to eq(1)
      expect(breakdown.completed.story_points).to eq(3)
      expect(breakdown.unfinished.work_package_count).to eq(1)
      expect(breakdown.unfinished.story_points).to eq(5)
    end
  end

  describe "#changed_after_start" do
    let(:sprint) do
      create(:sprint, project:,
                      start_date: Time.zone.today - 10.days,
                      finish_date: Time.zone.today + 4.days,
                      started_at: 10.days.ago)
    end

    let!(:stable_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 5,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    before { backdate_creation_journal(stable_work_package) }

    context "when more work packages were added than removed" do
      let!(:added_work_package_one) do
        create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 2,
                              created_at: sprint.start_date + 3.days, updated_at: sprint.start_date + 3.days)
      end

      let!(:added_work_package_two) do
        create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 3,
                              created_at: sprint.start_date + 3.days, updated_at: sprint.start_date + 3.days)
      end

      before { [added_work_package_one, added_work_package_two].each { |wp| backdate_creation_journal(wp) } }

      it "counts the additions, unaffected by the unchanged stable work package" do
        result = breakdown.changed_after_start
        expect(result.added_count).to eq(2)
        expect(result.removed_count).to eq(0)
        expect(result.added_story_points).to eq(2 + 3)
        expect(result.removed_story_points).to eq(0)
      end
    end

    context "when a work package was removed and none were added" do
      let!(:removed_work_package) do
        create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 4,
                              created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
      end

      before do
        backdate_creation_journal(removed_work_package)
        set_attribute_journalized(removed_work_package, :sprint_id=, nil, sprint.start_date + 2.days)
      end

      it "counts the removal" do
        result = breakdown.changed_after_start
        expect(result.added_count).to eq(0)
        expect(result.removed_count).to eq(1)
        expect(result.added_story_points).to eq(0)
        expect(result.removed_story_points).to eq(4)
      end
    end

    context "when a work package is removed and re-added, ending up back where it started" do
      let!(:flipping_work_package) do
        create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 1,
                              created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
      end

      before do
        backdate_creation_journal(flipping_work_package)
        set_attribute_journalized(flipping_work_package, :sprint_id=, nil, sprint.start_date + 1.day)
        set_attribute_journalized(flipping_work_package, :sprint_id=, sprint.id, sprint.start_date + 2.days)
      end

      it "reports no change at all, matching how the 'View all' baseline comparison would show it" do
        result = breakdown.changed_after_start
        expect(result.added_count).to eq(0)
        expect(result.removed_count).to eq(0)
        expect(result.added_story_points).to eq(0)
        expect(result.removed_story_points).to eq(0)
      end
    end

    context "when a work package flips an odd number of times, ending outside the sprint" do
      let!(:flipping_work_package) do
        create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 6,
                              created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
      end

      before do
        backdate_creation_journal(flipping_work_package)
        set_attribute_journalized(flipping_work_package, :sprint_id=, nil, sprint.start_date + 1.day)
        set_attribute_journalized(flipping_work_package, :sprint_id=, sprint.id, sprint.start_date + 2.days)
        set_attribute_journalized(flipping_work_package, :sprint_id=, nil, sprint.start_date + 3.days)
      end

      it "counts it once as removed, based on its final state rather than its three events" do
        result = breakdown.changed_after_start
        expect(result.added_count).to eq(0)
        expect(result.removed_count).to eq(1)
        expect(result.added_story_points).to eq(0)
        expect(result.removed_story_points).to eq(6)
      end
    end
  end

  describe "#added_after_start_ids and #removed_after_start_ids" do
    let(:sprint) do
      create(:sprint, project:,
                      start_date: Time.zone.today - 10.days,
                      finish_date: Time.zone.today + 4.days,
                      started_at: 10.days.ago)
    end

    let!(:stable_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 5,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    let!(:added_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 2,
                            created_at: sprint.start_date + 3.days, updated_at: sprint.start_date + 3.days)
    end

    let!(:removed_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 4,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    let!(:flipping_work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 1,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    before do
      [stable_work_package, added_work_package, removed_work_package, flipping_work_package].each do |wp|
        backdate_creation_journal(wp)
      end

      set_attribute_journalized(removed_work_package, :sprint_id=, nil, sprint.start_date + 2.days)
      set_attribute_journalized(flipping_work_package, :sprint_id=, nil, sprint.start_date + 1.day)
      set_attribute_journalized(flipping_work_package, :sprint_id=, sprint.id, sprint.start_date + 2.days)
    end

    it "returns the ids of the work packages that entered the sprint" do
      expect(breakdown.added_after_start_ids).to contain_exactly(added_work_package.id)
    end

    it "returns the ids of the work packages that left the sprint" do
      expect(breakdown.removed_after_start_ids).to contain_exactly(removed_work_package.id)
    end
  end
end
