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

RSpec.describe WorkPackages::SetScheduleService do
  create_shared_association_defaults_for_work_package_factory

  let(:work_package) do
    create(:work_package,
           subject: "subject",
           start_date: work_package_start_date,
           due_date: work_package_due_date)
  end
  let(:work_package_due_date) { Time.zone.today }
  let(:work_package_start_date) { nil }
  let(:initiating_work_package) { work_package }
  let(:instance) do
    described_class.new(user:, work_package:, initiated_by: initiating_work_package, switching_to_automatic_mode:)
  end
  let(:switching_to_automatic_mode) { [] }
  let!(:following) { [] }

  let(:follower1_start_date) { Time.zone.today + 1.day }
  let(:follower1_due_date) { Time.zone.today + 3.days }
  let(:follower1_lag) { 0 }
  let(:following_work_package1) do
    create_follower(follower1_start_date,
                    follower1_due_date,
                    { work_package => follower1_lag })
  end
  let(:follower2_start_date) { Time.zone.today + 4.days }
  let(:follower2_due_date) { Time.zone.today + 8.days }
  let(:follower2_lag) { 0 }
  let(:following_work_package2) do
    create_follower(follower2_start_date,
                    follower2_due_date,
                    { following_work_package1 => follower2_lag })
  end
  let(:follower3_start_date) { Time.zone.today + 9.days }
  let(:follower3_due_date) { Time.zone.today + 10.days }
  let(:follower3_lag) { 0 }
  let(:following_work_package3) do
    create_follower(follower3_start_date,
                    follower3_due_date,
                    { following_work_package2 => follower3_lag })
  end

  let(:parent_follower1_start_date) { follower1_start_date }
  let(:parent_follower1_due_date) { follower1_due_date }

  let(:parent_following_work_package1) do
    create_parent(following_work_package1)
  end

  let(:follower_sibling_work_package) do
    create_follower(follower1_due_date + 2.days,
                    follower1_due_date + 4.days,
                    {},
                    parent: parent_following_work_package1)
  end

  let(:attributes) { [:start_date] }

  def create_follower(start_date, due_date, predecessors, parent: nil)
    work_package = create(:work_package,
                          subject: "follower of #{predecessors.keys.map(&:subject).to_sentence}",
                          schedule_manually: false,
                          start_date:,
                          due_date:,
                          parent:)

    predecessors.map do |predecessor, lag|
      create(:follows_relation,
             lag:,
             from: work_package,
             to: predecessor)
    end

    work_package
  end

  def create_parent(child, start_date: child.start_date, due_date: child.due_date)
    create(:work_package,
           subject: "parent of #{child.subject}",
           schedule_manually: false,
           start_date:,
           due_date:).tap do |parent|
             child.parent = parent
             child.save
           end
  end

  def create_child(parent, start_date, due_date, **attributes)
    create(:work_package,
           subject: "child #{parent.children.count + 1} of #{parent.subject}",
           start_date:,
           due_date:,
           parent:,
           **attributes)
  end

  subject { instance.call(attributes) }

  shared_examples_for "reschedules" do
    it "successfully updates the following work packages", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      expect(subject).to be_success

      # returns only the original and the changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, *expected.keys)

      expected.each do |wp, (start_date, due_date)|
        expected_cause_type = "work_package_related_changed_times"
        result = subject.all_results.find { |result_wp| result_wp.id == wp.id }
        expect(result)
          .to be_present,
              "Expected work package ##{wp.id} '#{wp.subject}' to be rescheduled"

        expect(result.journal_cause.additional_attributes["work_package_id"])
          .to eql(initiating_work_package.id),
              "Expected work package change to ##{wp.id} to have been caused by ##{initiating_work_package.id}, but " \
              "it was caused by ##{result.journal_cause.additional_attributes[:work_package_id]}."

        expect(result.journal_cause.type)
        .to eql("work_package_related_changed_times"),
            "Expected work package change to ##{wp.id} to have been caused because ##{expected_cause_type}."

        expect(result.start_date)
          .to eql(start_date),
              "Expected work package ##{wp.id} '#{wp.subject}' " \
              "to have start date #{start_date.inspect}, got #{result.start_date.inspect}"
        expect(result.due_date)
          .to eql(due_date),
              "Expected work package ##{wp.id} '#{wp.subject}' " \
              "to have due date #{due_date.inspect}, got #{result.due_date.inspect}"

        duration = WorkPackages::Shared::AllDays.new.duration(start_date, due_date)

        expect(result.duration)
          .to eql(duration),
              "Expected work package ##{wp.id} '#{wp.subject}' " \
              "to have duration #{duration.inspect}, got #{result.duration.inspect}"
      end
    end
  end

  shared_examples_for "does not reschedule" do
    it "is successful and does not change any other work packages nor assign any journal cause" do
      expect(subject).to be_success

      expect(subject.all_results)
        .to contain_exactly(work_package)

      subject.all_results.each do |work_package|
        expect(work_package.journal_cause).to be_blank
      end
    end
  end

  context "without relation" do
    it "is success" do
      expect(subject)
        .to be_success
    end

    context "when the work package is automatically scheduled" do
      before do
        work_package.update_column(:schedule_manually, false)
      end

      it "switches to manual scheduling because it has no predecessors or children" do
        expect(subject)
          .to be_success

        # it is the result because it's the one the service is called with
        expect(subject.result).to be(work_package)
        # it is in the dependent results too because it has been modified by the service
        expect(subject.dependent_results.map(&:result)).to contain_exactly(work_package)
        # so it appears twice in the all_results
        expect(subject.all_results.map(&:subject))
          .to contain_exactly(work_package.subject, work_package.subject)
        expect(work_package.schedule_manually)
          .to be true
      end
    end
  end

  context "with a single successor" do
    let!(:following) do
      [following_work_package1]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
        end
      end
    end

    context "when moving forward with the follower having no due date" do
      let(:follower1_due_date) { nil }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, nil] }
        end
      end
    end

    context "when moving forward with the follower having no start date" do
      let(:follower1_start_date) { nil }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 6.days] }
        end
      end
    end

    context "when moving forward with the follower having some space left" do
      let(:follower1_start_date) { Time.zone.today + 3.days }
      let(:follower1_due_date) { Time.zone.today + 5.days }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
        end
      end
    end

    context "when moving forward with the follower having enough space left to start earlier" do
      let(:follower1_start_date) { Time.zone.today + 10.days }
      let(:follower1_due_date) { Time.zone.today + 12.days }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
        end
      end
    end

    context "when moving forward with the follower having some space left and a lag" do
      let(:follower1_start_date) { Time.zone.today + 5.days }
      let(:follower1_due_date) { Time.zone.today + 7.days }
      let(:follower1_lag) { 3 }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 9.days, Time.zone.today + 11.days] }
        end
      end
    end

    context "when moving forward with the follower not needing to be moved" do
      let(:follower1_start_date) { Time.zone.today + 6.days }
      let(:follower1_due_date) { Time.zone.today + 8.days }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      # no need to reschedule: the successor is already right after its predecessor
      it_behaves_like "does not reschedule"
    end

    context "when moving backwards" do
      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
        end
      end
    end

    context "when moving backwards with space between" do
      let(:follower1_start_date) { Time.zone.today + 3.days }
      let(:follower1_due_date) { Time.zone.today + 5.days }

      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
        end
      end
    end

    context 'when moving backwards with the follower having no start date (which should not happen) \
             and the due date after the scheduled to date' do
      let(:follower1_start_date) { nil }

      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today - 4.days, follower1_due_date] }
        end
      end
    end

    context 'when moving forward with the follower having no start date (which should not happen) \
             and the due date before the scheduled to date' do
      let(:follower1_start_date) { nil }

      before do
        work_package.due_date = follower1_due_date + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [follower1_due_date + 6.days, follower1_due_date + 6.days] }
        end
      end
    end

    context "when removing the dates on the predecessor" do
      before do
        work_package.start_date = work_package.due_date = nil
      end

      # The follower will keep its dates
      it_behaves_like "does not reschedule"

      context "when the follower has no start date but a due date" do
        let(:follower1_start_date) { nil }
        let(:follower1_due_date) { Time.zone.today + 15.days }

        it_behaves_like "does not reschedule"
      end
    end

    context "when not moving and the successor not having start & due date (e.g. creating relation)" do
      let(:follower1_start_date) { nil }
      let(:follower1_due_date) { nil }

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, nil] }
        end
      end
    end

    context "when not moving and the successor having due before predecessor due date (e.g. creating relation)" do
      let(:follower1_start_date) { nil }
      let(:follower1_due_date) { work_package_due_date - 5.days }

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 1.day] }
        end
      end
    end

    context "when not moving and the successor having start before predecessor due date (e.g. creating relation)" do
      let(:follower1_start_date) { work_package_due_date - 5.days }
      let(:follower1_due_date) { nil }

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, nil] }
        end
      end
    end

    context "when not moving and the successor having start and due before predecessor due date (e.g. creating relation)" do
      let(:follower1_start_date) { work_package_due_date - 5.days }
      let(:follower1_due_date) { work_package_due_date - 2.days }

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 4.days] }
        end
      end
    end

    context "when not having dates and the successor not having start & due date (e.g. creating relation)" do
      let(:work_package_due_date) { nil }
      let(:follower1_start_date) { nil }
      let(:follower1_due_date) { nil }

      it_behaves_like "does not reschedule"
    end

    context "with the successor having another predecessor which has no dates" do
      let(:following_work_package1) do
        create_follower(follower1_start_date,
                        follower1_due_date,
                        { work_package => follower1_lag,
                          another_predecessor => 0 })
      end
      let(:another_predecessor) do
        create(:work_package,
               start_date: nil,
               due_date: nil)
      end

      context "when moving forward" do
        before do
          work_package.due_date = Time.zone.today + 5.days
        end

        it_behaves_like "reschedules" do
          let(:expected) do
            { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
          end
        end
      end

      context "when moving backwards" do
        before do
          work_package.due_date = Time.zone.today - 5.days
        end

        it_behaves_like "reschedules" do
          let(:expected) do
            { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
          end
        end
      end
    end

    context "when switching the successor to automatic mode without moving dates (adding relation)" do
      let(:switching_to_automatic_mode) { [following_work_package1] }

      before do
        following_work_package1.update_column(:schedule_manually, true)
      end

      it "does not reschedule but switches the successor to automatic mode" do
        expect(subject).to be_success

        # returns the original and the successor which did not changed dates,
        # but changed scheduling mode
        expect(subject.all_results)
          .to contain_exactly(work_package, following_work_package1)

        expect(subject.all_results.last.schedule_manually).to be(false)
      end
    end
  end

  context "with only a parent scheduled automatically" do
    let!(:parent_work_package) do
      create(:work_package, subject: "parent", schedule_manually: false).tap do |parent|
        work_package.parent = parent
        work_package.save
      end
    end
    let(:work_package_start_date) { Time.zone.today - 5.days }

    it_behaves_like "reschedules" do
      let(:expected) do
        { parent_work_package => [work_package_start_date, work_package_due_date] }
      end
    end
  end

  context "with a parent having a follower" do
    let(:work_package_start_date) { Time.zone.today }
    let(:work_package_due_date) { Time.zone.today + 5.days }
    let!(:parent_work_package) do
      create(:work_package,
             subject: "parent of #{work_package.subject}",
             schedule_manually: false,
             start_date: Time.zone.today,
             due_date: Time.zone.today + 1.day).tap do |parent|
        work_package.parent = parent
        work_package.save
      end
    end
    let!(:follower_of_parent_work_package) do
      create_follower(Time.zone.today + 4.days,
                      Time.zone.today + 6.days,
                      { parent_work_package => 0 })
    end

    it_behaves_like "reschedules" do
      let(:expected) do
        { parent_work_package => [work_package_start_date, work_package_due_date],
          follower_of_parent_work_package => [work_package_due_date + 1.day, work_package_due_date + 3.days] }
      end
    end

    # There is a bug in the scheduling that happens if the dependencies
    # array order is: [sibling child, follower of parent, parent]
    #
    # In this case, as the follower of parent only knows about direct
    # dependencies (and not about the transitive dependencies of children of
    # predecessor), it will be made the first in the order, based on the
    # current algorithm. And as the parent depends on its child, it will
    # come after it.
    #
    # Based on the algorithm when this test was written, the resulting
    # scheduling order will be [follower of parent, sibling child, parent],
    # which is wrong: if follower of parent is rescheduled first, then it
    # will not change because its predecessor, the parent, has not been
    # scheduled yet.
    #
    # The expected and right order is [sibling child, parent, follower of
    # parent].
    #
    # That's why the WorkPackage.for_scheduling call is mocked to customize
    # the order of the returned work_packages to reproduce this bug.
    context "with also a sibling follower with same parent" do
      let!(:sibling_follower_of_work_package) do
        create_follower(Time.zone.today + 2.days,
                        Time.zone.today + 3.days,
                        { work_package => 0 },
                        parent: parent_work_package)
      end

      before do
        allow(WorkPackage)
          .to receive(:for_scheduling)
          .and_wrap_original do |method, *args, **kwargs|
            wanted_order = [sibling_follower_of_work_package, follower_of_parent_work_package, parent_work_package]
            method.call(*args, **kwargs).in_order_of(:id, wanted_order.map(&:id))
          end
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { sibling_follower_of_work_package => [work_package_due_date + 1.day, work_package_due_date + 2.days],
            parent_work_package => [work_package_start_date, work_package_due_date + 2.days],
            follower_of_parent_work_package => [work_package_due_date + 3.days, work_package_due_date + 5.days] }
        end
      end
    end
  end

  context "with a single successor having a parent" do
    let!(:following) do
      [following_work_package1,
       parent_following_work_package1]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            parent_following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
        end
      end
    end

    context "when moving forward with the parent having another child not being moved" do
      let(:parent_follower1_start_date) { follower1_start_date }
      let(:parent_follower1_due_date) { follower1_due_date + 4.days }

      let!(:following) do
        [following_work_package1,
         parent_following_work_package1,
         follower_sibling_work_package]
      end

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            parent_following_work_package1 => [Time.zone.today + 5.days, Time.zone.today + 8.days] }
        end
      end
    end

    context "when moving backwards" do
      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days],
            parent_following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
        end
      end
    end
  end

  context "with a single successor having a child scheduled manually" do
    let(:child_start_date) { follower1_start_date }
    let(:child_due_date) { follower1_due_date }

    let(:child_work_package) { create_child(following_work_package1, child_start_date, child_due_date) }

    let!(:following) do
      [following_work_package1,
       child_work_package]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      # does not reschedules the child, so the follower keeps its dates
      it_behaves_like "does not reschedule"
    end
  end

  context "with a single successor having a child scheduled automatically" do
    let(:child_start_date) { follower1_start_date }
    let(:child_due_date) { follower1_due_date }

    let(:child_work_package) do
      create_child(following_work_package1,
                   child_start_date,
                   child_due_date,
                   schedule_manually: false)
    end

    let!(:following) do
      [following_work_package1,
       child_work_package]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            child_work_package => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
        end
      end
    end
  end

  context "with a single successor having two children scheduled automatically" do
    let(:follower1_start_date) { work_package_due_date + 1.day }
    let(:follower1_due_date) { work_package_due_date + 10.days }
    let(:child1_start_date) { follower1_start_date }
    let(:child1_due_date) { follower1_start_date + 3.days }
    let(:child2_start_date) { follower1_due_date - 1.day }
    let(:child2_due_date) { follower1_due_date }

    let(:child1_work_package) do
      create_child(following_work_package1,
                   child1_start_date,
                   child1_due_date,
                   schedule_manually: false)
    end
    let(:child2_work_package) do
      create_child(following_work_package1,
                   child2_start_date,
                   child2_due_date,
                   schedule_manually: false)
    end

    let!(:following) do
      [following_work_package1,
       child1_work_package,
       child2_work_package]
    end

    context "with unchanged dates (e.g. when creating a follows relation) and successor starting 1 day after scheduled" do
      it_behaves_like "reschedules" do
        let(:expected) do
          {
            # child1 is not rescheduled as it is already starting right after the moved work package
            # child2 is rescheduled right after the moved work package
            child2_work_package => [work_package_due_date + 1.day, work_package_due_date + 2.days],
            # following is rescheduled to match its 2 children's dates
            following_work_package1 => [work_package_due_date + 1.day, work_package_due_date + 4.days]
          }
        end
      end
    end

    context "with unchanged dates (e.g. when creating a follows relation) and successor starting 3 days after scheduled" do
      let(:follower1_start_date) { work_package_due_date + 3.days }
      let(:follower1_due_date) { follower1_start_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 6.days }
      let(:child2_start_date) { follower1_due_date - 1.day }
      let(:child2_due_date) { follower1_due_date }

      it_behaves_like "reschedules" do
        let(:expected) do
          {
            # child1 and child2 rescheduled right after the moved work package
            child1_work_package => [work_package_due_date + 1.day, work_package_due_date + 7.days],
            child2_work_package => [work_package_due_date + 1.day, work_package_due_date + 2.days],
            # following is rescheduled to match its 2 children's dates
            following_work_package1 => [work_package_due_date + 1.day, work_package_due_date + 7.days]
          }
        end
      end
    end

    context "with unchanged dates (e.g. when creating a follows relation) and successor's first child needs to be rescheduled" do
      let(:follower1_start_date) { work_package_due_date - 3.days }
      let(:follower1_due_date) { work_package_due_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 6.days }
      let(:child2_start_date) { follower1_due_date - 5.days }
      let(:child2_due_date) { follower1_due_date }

      # following parent is reduced in length as the children allow to be executed at the same time
      it_behaves_like "reschedules" do
        let(:expected) do
          { # child1 and child2 rescheduled right after the moved work package
            child1_work_package => [work_package_due_date + 1.day, work_package_due_date + 7.days],
            child2_work_package => [work_package_due_date + 1.day, work_package_due_date + 6.days],
            # following is rescheduled to match its 2 children's dates
            following_work_package1 => [work_package_due_date + 1.day, work_package_due_date + 7.days]
          }
        end
      end
    end

    context "with unchanged dates (e.g. when creating a follows relation) and successor's children need to be rescheduled" do
      let(:follower1_start_date) { work_package_due_date - 8.days }
      let(:follower1_due_date) { work_package_due_date + 10.days }
      let(:child1_start_date) { follower1_start_date }
      let(:child1_due_date) { follower1_start_date + 4.days }
      let(:child2_start_date) { follower1_start_date + 6.days }
      let(:child2_due_date) { follower1_due_date }

      # following parent is reduced in length and children are rescheduled
      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package_due_date + 1.day, follower1_start_date + 21.days],
            child1_work_package => [work_package_due_date + 1.day, child1_due_date + 9.days],
            child2_work_package => [work_package_due_date + 1.day, follower1_start_date + 21.days] }
        end
      end
    end
  end

  context "with a chain of successors" do
    let(:follower1_start_date) { Time.zone.today + 1.day }
    let(:follower1_due_date) { Time.zone.today + 3.days }
    let(:follower2_start_date) { Time.zone.today + 4.days }
    let(:follower2_due_date) { Time.zone.today + 8.days }
    let(:follower3_start_date) { Time.zone.today + 9.days }
    let(:follower3_due_date) { Time.zone.today + 10.days }

    let!(:following) do
      [following_work_package1,
       following_work_package2,
       following_work_package3]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            following_work_package2 => [Time.zone.today + 9.days, Time.zone.today + 13.days],
            following_work_package3 => [Time.zone.today + 14.days, Time.zone.today + 15.days] }
        end
      end
    end

    context "when moving forward with some space between the followers" do
      let(:follower1_start_date) { Time.zone.today + 1.day }
      let(:follower1_due_date) { Time.zone.today + 3.days }
      let(:follower2_start_date) { Time.zone.today + 7.days }
      let(:follower2_due_date) { Time.zone.today + 10.days }
      let(:follower3_start_date) { Time.zone.today + 17.days }
      let(:follower3_due_date) { Time.zone.today + 18.days }

      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            following_work_package2 => [Time.zone.today + 9.days, Time.zone.today + 12.days],
            following_work_package3 => [Time.zone.today + 13.days, Time.zone.today + 14.days] }
        end
      end
    end

    context "when moving backwards" do
      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 3.days],
            following_work_package2 => [work_package.due_date + 4.days, work_package.due_date + 8.days],
            following_work_package3 => [work_package.due_date + 9.days, work_package.due_date + 10.days] }
        end
      end
    end
  end

  context "with a chain of successors with two paths leading to the same work package in the end" do
    let(:follower3_start_date) { Time.zone.today + 4.days }
    let(:follower3_due_date) { Time.zone.today + 7.days }
    let(:follower3_lag) { 0 }
    let(:following_work_package3) do
      create_follower(follower3_start_date,
                      follower3_due_date,
                      { work_package => follower3_lag })
    end
    let(:follower4_start_date) { Time.zone.today + 9.days }
    let(:follower4_due_date) { Time.zone.today + 10.days }
    let(:follower4_lag2) { 0 }
    let(:follower4_lag3) { 0 }
    let(:following_work_package4) do
      create_follower(follower4_start_date,
                      follower4_due_date,
                      { following_work_package2 => follower4_lag2, following_work_package3 => follower4_lag3 })
    end
    let!(:following) do
      [following_work_package1,
       following_work_package2,
       following_work_package3,
       following_work_package4]
    end

    context "when moving forward" do
      before do
        work_package.due_date = Time.zone.today + 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
            following_work_package2 => [Time.zone.today + 9.days, Time.zone.today + 13.days],
            following_work_package3 => [Time.zone.today + 6.days, Time.zone.today + 9.days],
            following_work_package4 => [Time.zone.today + 14.days, Time.zone.today + 15.days] }
        end
      end
    end

    context "when moving backwards" do
      before do
        work_package.due_date = Time.zone.today - 5.days
      end

      it_behaves_like "reschedules" do
        let(:expected) do
          { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 3.days],
            following_work_package2 => [work_package.due_date + 4.days, work_package.due_date + 8.days],
            following_work_package3 => [work_package.due_date + 1.day, work_package.due_date + 4.days],
            following_work_package4 => [work_package.due_date + 9.days, work_package.due_date + 10.days] }
        end
      end
    end
  end

  context "with deep hierarchy of work packages" do
    before do
      work_package.due_date = Time.zone.today - 5.days
    end

    def create_hierarchy(parent, nb_children_by_levels)
      nb_children, *remaining_levels = nb_children_by_levels
      children = create_list(:work_package, nb_children, parent:)
      parent.update(schedule_manually: false)
      if remaining_levels.any?
        children.each do |child|
          create_hierarchy(child, remaining_levels)
        end
      end
    end

    it "does not fail with a SystemStackError (regression #43894)" do
      parent = create(:work_package, start_date: Date.current, due_date: Date.current)
      hierarchy = [1, 1, 1, 1, 2, 4, 4, 4]
      create_hierarchy(parent, hierarchy)

      # The bug triggers when moving work package is in the middle of the
      # hierarchy
      work_package.parent = parent.children.first.children.first.children.first
      work_package.save

      expect { instance.call(attributes) }
        .not_to raise_error
    end
  end
end
