#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

describe WorkPackages::SetScheduleService, 'working days', with_flag: { work_packages_duration_field_active: true } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { create(:week_days) }

  let(:instance) do
    described_class.new(user:, work_package:)
  end
  let(:changed_attributes) { [:start_date] }

  subject { instance.call(changed_attributes) }

  context 'when moved successor covers non-working days' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days          | MTWTFss |
      work_package  | XX      |
      follower      |   XXX   | after work_package
    CHART

    before do
      change_schedule([work_package], <<~CHART)
        days          | MTWTFss |
        work_package  | XXXX    |
      CHART
    end

    it 'extends to a later due date to keep the same duration' do
      expect_schedule(subject.all_results, <<~CHART)
        days          | MTWTFss   |
        work_package  | XXXX      |
        follower      |     X..XX |
      CHART
      expect(follower.duration).to eq(3)
    end
  end

  context 'with a single successor' do
    context 'when moved forward with the follower having no due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days          | MTWTFss   |
        work_package  | X         |
        follower      |   [       | after work_package
      CHART

      context 'on a day in the middle on working days' do
        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFss |
            work_package  | XXXX    |
          CHART
        end

        it 'reschedules follower to start the next day after its predecessor due date' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFss   |
            work_package  | XXXX      |
            follower      |     [     |
          CHART
        end
      end

      context 'on a day just before non working days' do
        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFss |
            work_package  | XXXXX   |
          CHART
        end

        it 'reschedules follower to start after the non working days' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFss   |
            work_package  | XXXXX     |
            follower      |        [  |
          CHART
        end
      end
    end

    context 'when moving forward with the follower having only due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days          | MTWTFss |
        work_package  | ]       |
        follower      |    ]    | after work_package
      CHART

      context 'on a day in the middle on working days' do
        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFss |
            work_package  |    ]    |
          CHART
        end

        it 'reschedules follower to start and end right after its predecessor with a default duration of 1 day' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFss |
            work_package  |    ]    |
            follower      |     X   |
          CHART
        end
      end

      context 'on a day just before non working days' do
        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFss |
            work_package  |     ]   |
          CHART
        end

        it 'reschedules follower to start and end after the non working days with a default duration of 1 day' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFss   |
            work_package  |     ]     |
            follower      |        X  |
          CHART
        end
      end
    end

    #   context 'when moving forward with the follower having some space left' do
    #     let(:follower1_start_date) { Time.zone.today + 3.days }
    #     let(:follower1_due_date) { Time.zone.today + 5.days }

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
    #       end
    #     end
    #   end

    #   context 'when moving forward with the follower having enough space left to not be moved at all' do
    #     let(:follower1_start_date) { Time.zone.today + 10.days }
    #     let(:follower1_due_date) { Time.zone.today + 12.days }

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         {}
    #       end
    #     end
    #   end

    #   context 'when moving forward with the follower having some space left and a delay' do
    #     let(:follower1_start_date) { Time.zone.today + 5.days }
    #     let(:follower1_due_date) { Time.zone.today + 7.days }
    #     let(:follower1_delay) { 3 }

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 9.days, Time.zone.today + 11.days] }
    #       end
    #     end
    #   end

    #   context 'when moving forward with the follower not needing to be moved' do
    #     let(:follower1_start_date) { Time.zone.today + 6.days }
    #     let(:follower1_due_date) { Time.zone.today + 8.days }

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       # Nothing should be rescheduled
    #       let(:expected) do
    #         {}
    #       end
    #     end
    #   end

    #   context 'when moving backwards' do
    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with space between' do
    #     let(:follower1_start_date) { Time.zone.today + 3.days }
    #     let(:follower1_due_date) { Time.zone.today + 5.days }

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 2.days, Time.zone.today] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with the follower having another relation limiting movement' do
    #     let!(:other_work_package) do
    #       create(:work_package,
    #              type:,
    #              start_date: follower1_start_date - 8.days,
    #              due_date: follower1_start_date - 5.days).tap do |wp|
    #         create(:follows_relation,
    #                delay: 3,
    #                to: wp,
    #                from: following_work_package1)
    #       end
    #     end

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today, Time.zone.today + 2.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with the follower having no start date (which should not happen) \
    #            and the due date after the scheduled to date' do
    #     let(:follower1_start_date) { nil }

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, follower1_due_date] }
    #       end
    #     end
    #   end

    #   context 'when moving forward with the follower having no start date (which should not happen) \
    #            and the due date before the scheduled to date' do
    #     let(:follower1_start_date) { nil }

    #     before do
    #       work_package.due_date = follower1_due_date + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [follower1_due_date + 6.days, follower1_due_date + 6.days] }
    #       end
    #     end
    #   end

    #   context 'when removing the dates on the predecessor' do
    #     before do
    #       work_package.start_date = work_package.due_date = nil
    #     end

    #     it_behaves_like 'reschedules' do
    #       # The follower will keep its dates
    #       let(:expected) do
    #         {}
    #       end
    #     end

    #     context 'when the follower has no start date but a due date' do
    #       let(:follower1_start_date) { nil }
    #       let(:follower1_due_date) { Time.zone.today + 15.days }

    #       it_behaves_like 'reschedules' do
    #         # Nothing should be rescheduled
    #         let(:expected) do
    #           {}
    #         end
    #       end
    #     end
    #   end

    #   context 'when not moving and the successor not having start & due date (e.g. creating relation)' do
    #     let(:follower1_start_date) { nil }
    #     let(:follower1_due_date) { nil }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package.due_date + 1.day, nil] }
    #       end
    #     end
    #   end

    #   context 'when not moving and the successor having due before predecessor due date (e.g. creating relation)' do
    #     let(:follower1_start_date) { nil }
    #     let(:follower1_due_date) { work_package_due_date - 5.days }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 1.day] }
    #       end
    #     end
    #   end

    #   context 'when not moving and the successor having start before predecessor due date (e.g. creating relation)' do
    #     let(:follower1_start_date) { work_package_due_date - 5.days }
    #     let(:follower1_due_date) { nil }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package.due_date + 1.day, nil] }
    #       end
    #     end
    #   end

    #   context 'when not moving and the successor having start and due before predecessor due date (e.g. creating relation)' do
    #     let(:follower1_start_date) { work_package_due_date - 5.days }
    #     let(:follower1_due_date) { work_package_due_date - 2.days }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package.due_date + 1.day, work_package.due_date + 4.days] }
    #       end
    #     end
    #   end

    #   context 'when not having dates and the successor not having start & due date (e.g. creating relation)' do
    #     let(:work_package_due_date) { nil }
    #     let(:follower1_start_date) { nil }
    #     let(:follower1_due_date) { nil }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         {}
    #       end
    #     end
    #   end

    #   context 'with the successor having another predecessor which has no dates' do
    #     let(:following_work_package1) do
    #       create_follower(follower1_start_date,
    #                       follower1_due_date,
    #                       { work_package => follower1_delay,
    #                         another_successor => 0 })
    #     end
    #     let(:another_successor) do
    #       create(:work_package,
    #              start_date: nil,
    #              due_date: nil)
    #     end

    #     context 'when moving forward' do
    #       before do
    #         work_package.due_date = Time.zone.today + 5.days
    #       end

    #       it_behaves_like 'reschedules' do
    #         let(:expected) do
    #           { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
    #         end
    #       end
    #     end

    #     context 'when moving backwards' do
    #       before do
    #         work_package.due_date = Time.zone.today - 5.days
    #       end

    #       it_behaves_like 'reschedules' do
    #         let(:expected) do
    #           { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
    #         end
    #       end
    #     end
    #   end
    # end

    # context 'with only a parent' do
    #   let!(:parent_work_package) do
    #     create(:work_package).tap do |parent|
    #       work_package.parent = parent
    #       work_package.save
    #     end
    #   end
    #   let(:work_package_start_date) { Time.zone.today - 5.days }

    #   it_behaves_like 'reschedules' do
    #     let(:expected) do
    #       { parent_work_package => [work_package_start_date, work_package_due_date] }
    #     end
    #   end
    # end

    # context 'with a parent having a follower' do
    #   let(:work_package_start_date) { Time.zone.today }
    #   let(:work_package_due_date) { Time.zone.today + 5.days }
    #   let!(:parent_work_package) do
    #     create(:work_package,
    #            subject: "parent of #{work_package.subject}",
    #            start_date: Time.zone.today,
    #            due_date: Time.zone.today + 1.day).tap do |parent|
    #       work_package.parent = parent
    #       work_package.save
    #     end
    #   end
    #   let!(:follower_of_parent_work_package) do
    #     create_follower(Time.zone.today + 4.days,
    #                     Time.zone.today + 6.days,
    #                     { parent_work_package => 0 })
    #   end

    #   it_behaves_like 'reschedules' do
    #     let(:expected) do
    #       { parent_work_package => [work_package_start_date, work_package_due_date],
    #         follower_of_parent_work_package => [work_package_due_date + 1.day, work_package_due_date + 3.days] }
    #     end
    #   end

    #   # There is a bug in the scheduling that happens if the dependencies
    #   # array order is: [sibling child, follower of parent, parent]
    #   #
    #   # In this case, as the follower of parent only knows about direct
    #   # dependencies (and not about the transitive dependencies of children of
    #   # predecessor), it will be made the first in the order, based on the
    #   # current algorithm. And as the parent depends on its child, it will
    #   # come after it.
    #   #
    #   # Based on the algorithm when this test was written, the resulting
    #   # scheduling order will be [follower of parent, sibling child, parent],
    #   # which is wrong: if follower of parent is rescheduled first, then it
    #   # will not change because its predecessor, the parent, has not been
    #   # scheduled yet.
    #   #
    #   # The expected and right order is [sibling child, parent, follower of
    #   # parent].
    #   #
    #   # That's why the WorkPackage.for_scheduling call is mocked to customize
    #   # the order of the returned work_packages to reproduce this bug.
    #   context 'with also a sibling follower with same parent' do
    #     let!(:sibling_follower_of_work_package) do
    #       create_follower(Time.zone.today + 2.days,
    #                       Time.zone.today + 3.days,
    #                       { work_package => 0 },
    #                       parent: parent_work_package)
    #     end

    #     before do
    #       allow(WorkPackage)
    #         .to receive(:for_scheduling)
    #         .and_wrap_original do |method, *args|
    #           wanted_order = [sibling_follower_of_work_package, follower_of_parent_work_package, parent_work_package]
    #           method.call(*args).in_order_of(:id, wanted_order.map(&:id))
    #         end
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { sibling_follower_of_work_package => [work_package_due_date + 1.day, work_package_due_date + 2.days],
    #           parent_work_package => [work_package_start_date, work_package_due_date + 2.days],
    #           follower_of_parent_work_package => [work_package_due_date + 3.days, work_package_due_date + 5.days] }
    #       end
    #     end
    #   end
    # end

    # context 'with a single successor having a parent' do
    #   let!(:following) do
    #     [following_work_package1,
    #      parent_following_work_package1]
    #   end

    #   context 'when moving forward' do
    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
    #           parent_following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
    #       end
    #     end
    #   end

    #   context 'when moving forward with the parent having another child not being moved' do
    #     let(:parent_follower1_start_date) { follower1_start_date }
    #     let(:parent_follower1_due_date) { follower1_due_date + 4.days }

    #     let!(:following) do
    #       [following_work_package1,
    #        parent_following_work_package1,
    #        follower_sibling_work_package]
    #     end

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
    #           parent_following_work_package1 => [Time.zone.today + 5.days, Time.zone.today + 8.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards' do
    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days],
    #           parent_following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with the parent having another relation limiting movement' do
    #     let!(:other_work_package) do
    #       create(:work_package,
    #              type:,
    #              project:,
    #              author: user,
    #              start_date: Time.zone.today - 8.days,
    #              due_date: Time.zone.today - 4.days).tap do |wp|
    #         create(:follows_relation,
    #                delay: 2,
    #                to: wp,
    #                from: parent_following_work_package1)
    #       end
    #     end

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 1.day, Time.zone.today + 1.day],
    #           parent_following_work_package1 => [Time.zone.today - 1.day, Time.zone.today + 1.day] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with the parent having another relation not limiting movement' do
    #     let(:other_work_package) do
    #       create(:work_package,
    #              type:,
    #              start_date: Time.zone.today - 10.days,
    #              due_date: Time.zone.today - 9.days)
    #     end

    #     let(:other_follow_relation) do
    #       create(:follows_relation,
    #              delay: 2,
    #              to: other_work_package,
    #              from: parent_following_work_package1)
    #     end

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days],
    #           parent_following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards with the parent having another child not being moved' do
    #     let(:parent_follower1_start_date) { follower1_start_date }
    #     let(:parent_follower1_due_date) { follower1_due_date + 4.days }

    #     let!(:following) do
    #       [following_work_package1,
    #        parent_following_work_package1,
    #        follower_sibling_work_package]
    #     end

    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days],
    #           parent_following_work_package1 => [Time.zone.today - 4.days, Time.zone.today + 7.days] }
    #       end
    #     end
    #   end
    # end

    # context 'with a single successor having a child' do
    #   let(:child_start_date) { follower1_start_date }
    #   let(:child_due_date) { follower1_due_date }

    #   let(:child_work_package) { create_follower_child(following_work_package1, child_start_date, child_due_date) }

    #   let!(:following) do
    #     [following_work_package1,
    #      child_work_package]
    #   end

    #   context 'when moving forward' do
    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
    #           child_work_package => [Time.zone.today + 6.days, Time.zone.today + 8.days] }
    #       end
    #     end
    #   end
    # end

    # context 'with a single successor having two children' do
    #   let(:follower1_start_date) { work_package_due_date + 1.day }
    #   let(:follower1_due_date) { work_package_due_date + 10.days }
    #   let(:child1_start_date) { follower1_start_date }
    #   let(:child1_due_date) { follower1_start_date + 3.days }
    #   let(:child2_start_date) { follower1_start_date + 8.days }
    #   let(:child2_due_date) { follower1_due_date }

    #   let(:child1_work_package) { create_follower_child(following_work_package1, child1_start_date, child1_due_date) }
    #   let(:child2_work_package) { create_follower_child(following_work_package1, child2_start_date, child2_due_date) }

    #   let!(:following) do
    #     [following_work_package1,
    #      child1_work_package,
    #      child2_work_package]
    #   end

    #   context 'with unchanged dates (e.g. when creating a follows relation) and successor starting 1 day after scheduled' do
    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         {}
    #       end
    #     end
    #   end

    #   context 'with unchanged dates (e.g. when creating a follows relation) and successor starting 3 days after scheduled' do
    #     let(:follower1_start_date) { work_package_due_date + 3.days }
    #     let(:follower1_due_date) { follower1_start_date + 10.days }
    #     let(:child1_start_date) { follower1_start_date }
    #     let(:child1_due_date) { follower1_start_date + 6.days }
    #     let(:child2_start_date) { follower1_start_date + 8.days }
    #     let(:child2_due_date) { follower1_due_date }

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         {}
    #       end
    #     end
    #   end

    #   context 'with unchanged dates (e.g. when creating a follows relation) and successor\'s first child needs rescheduled' do
    #     let(:follower1_start_date) { work_package_due_date - 3.days }
    #     let(:follower1_due_date) { work_package_due_date + 10.days }
    #     let(:child1_start_date) { follower1_start_date }
    #     let(:child1_due_date) { follower1_start_date + 6.days }
    #     let(:child2_start_date) { follower1_start_date + 8.days }
    #     let(:child2_due_date) { follower1_due_date }

    #     # following parent is reduced in length as the children allow to be executed at the same time
    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package_due_date + 1.day, follower1_due_date],
    #           child1_work_package => [work_package_due_date + 1.day, follower1_start_date + 10.days] }
    #       end
    #     end
    #   end

    #   context 'with unchanged dates (e.g. when creating a follows relation) and successor\s children need to be rescheduled' do
    #     let(:follower1_start_date) { work_package_due_date - 8.days }
    #     let(:follower1_due_date) { work_package_due_date + 10.days }
    #     let(:child1_start_date) { follower1_start_date }
    #     let(:child1_due_date) { follower1_start_date + 4.days }
    #     let(:child2_start_date) { follower1_start_date + 6.days }
    #     let(:child2_due_date) { follower1_due_date }

    #     # following parent is reduced in length and children are rescheduled
    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [work_package_due_date + 1.day, follower1_start_date + 21.days],
    #           child1_work_package => [work_package_due_date + 1.day, child1_due_date + 9.days],
    #           child2_work_package => [work_package_due_date + 1.day, follower1_start_date + 21.days] }
    #       end
    #     end
    #   end
    # end

    # context 'with a chain of successors' do
    #   let(:follower1_start_date) { Time.zone.today + 1.day }
    #   let(:follower1_due_date) { Time.zone.today + 3.days }
    #   let(:follower2_start_date) { Time.zone.today + 4.days }
    #   let(:follower2_due_date) { Time.zone.today + 8.days }
    #   let(:follower3_start_date) { Time.zone.today + 9.days }
    #   let(:follower3_due_date) { Time.zone.today + 10.days }

    #   let!(:following) do
    #     [following_work_package1,
    #      following_work_package2,
    #      following_work_package3]
    #   end

    #   context 'when moving forward' do
    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
    #           following_work_package2 => [Time.zone.today + 9.days, Time.zone.today + 13.days],
    #           following_work_package3 => [Time.zone.today + 14.days, Time.zone.today + 15.days] }
    #       end
    #     end
    #   end

    #   context 'when moving forward with some space between the followers' do
    #     let(:follower1_start_date) { Time.zone.today + 1.day }
    #     let(:follower1_due_date) { Time.zone.today + 3.days }
    #     let(:follower2_start_date) { Time.zone.today + 7.days }
    #     let(:follower2_due_date) { Time.zone.today + 10.days }
    #     let(:follower3_start_date) { Time.zone.today + 17.days }
    #     let(:follower3_due_date) { Time.zone.today + 18.days }

    #     before do
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today + 6.days, Time.zone.today + 8.days],
    #           following_work_package2 => [Time.zone.today + 9.days, Time.zone.today + 12.days] }
    #       end
    #     end
    #   end

    #   context 'when moving backwards' do
    #     before do
    #       work_package.due_date = Time.zone.today - 5.days
    #     end

    #     it_behaves_like 'reschedules' do
    #       let(:expected) do
    #         { following_work_package1 => [Time.zone.today - 4.days, Time.zone.today - 2.days],
    #           following_work_package2 => [Time.zone.today - 1.day, Time.zone.today + 3.days],
    #           following_work_package3 => [Time.zone.today + 4.days, Time.zone.today + 5.days] }
    #       end
    #     end
    #   end
    # end

    # context 'with a chain of successors with two paths leading to the same work package in the end' do
    #   let_schedule(<<~CHART)
    #                   | MTWTFSS     |
    #     work_package  | X           |
    #     follower1     |  XXX        | after work_package
    #     follower2     |     XXXXX   | after follower1
    #     follower3     |     XXXX    | after work_package
    #     follower4     |          XX | after follower2, after follower3
    #   CHART

    #   context 'when moving forward' do
    #     before do
    #       change_schedule(<<~CHART)
    #                       | MTWTFss |
    #         work_package  |      X  |
    #       CHART
    #     end

    #     it 'reschedules' do
    #       expect_schedule(subject.all_results, <<~CHART)
    #                       | MTWTFSS          |
    #         work_package  |      X           |
    #         follower1     |       XXX        |
    #         follower2     |          XXXXX   |
    #         follower3     |       XXXX       |
    #         follower4     |               XX |
    #       CHART
    #     end
    #   end

    #   context 'when moving backwards' do
    #     before do
    #       change_schedule(<<~CHART)
    #                       |      MTWTFSS |
    #         work_package  | X            |
    #       CHART
    #     end

    #     it 'reschedules' do
    #       expect_schedule(subject.all_results, <<~CHART)
    #                       |      MTWTFSS |
    #         work_package  | X            |
    #         follower1     |  XXX         |
    #         follower2     |     XXXXX    |
    #         follower3     |     XXXX     |
    #         follower4     |          XX  |
    #       CHART
    #     end
    #   end
    # end

    # context 'when setting the parent' do
    #   let(:new_parent_work_package) { create(:work_package) }
    #   let(:changed_attributes) { [:parent] }

    #   before do
    #     allow(new_parent_work_package)
    #       .to receive(:soonest_start)
    #             .and_return(soonest_date)
    #     allow(work_package)
    #       .to receive(:parent)
    #             .and_return(new_parent_work_package)
    #   end

    #   context "with the parent being restricted in it's ability to be moved" do
    #     let(:soonest_date) { Time.zone.today + 3.days }

    #     it 'sets the start date to the earliest possible date' do
    #       subject

    #       expect(work_package.start_date).to eql(Time.zone.today + 3.days)
    #     end
    #   end

    #   context 'with the parent being restricted but work package already having dates set' do
    #     let(:soonest_date) { Time.zone.today + 3.days }

    #     before do
    #       work_package.start_date = Time.zone.today + 4.days
    #       work_package.due_date = Time.zone.today + 5.days
    #     end

    #     it 'sets the dates to provided dates' do
    #       subject

    #       expect(work_package.start_date).to eql(Time.zone.today + 4.days)
    #       expect(work_package.due_date).to eql(Time.zone.today + 5.days)
    #     end
    #   end

    #   context 'with the parent being restricted but the attributes define an earlier date' do
    #     let(:soonest_date) { Time.zone.today + 3.days }

    #     before do
    #       work_package.start_date = Time.zone.today + 1.day
    #       work_package.due_date = Time.zone.today + 2.days
    #     end

    #     # This would be invalid but the dates should be set nevertheless
    #     # so we can have a correct error handling.
    #     it 'sets the dates to provided dates' do
    #       subject

    #       expect(work_package.start_date).to eql(Time.zone.today + 1.day)
    #       expect(work_package.due_date).to eql(Time.zone.today + 2.days)
    #     end
    #   end
  end
end
