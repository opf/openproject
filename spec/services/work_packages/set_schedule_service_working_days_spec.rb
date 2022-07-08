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

  context 'with a single successor' do
    context 'when moving successor will cover non-working days' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days          | MTWTFSS |
        work_package  | XX      |
        follower      |   XXX   | follows work_package
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days          | MTWTFSS |
          work_package  | XXXX    |
        CHART
      end

      it 'extends to a later due date to keep the same duration' do
        expect_schedule(subject.all_results, <<~CHART)
          days          | MTWTFSS   |
          work_package  | XXXX      |
          follower      |     X..XX |
        CHART
        expect(follower.duration).to eq(3)
      end
    end

    context 'when moved predecessor covers non-working days' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days          | MTWTFSS      |
        work_package  |    XX        |
        follower      |        XXX   | follows work_package
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days          | MTWTFSS     |
          work_package  |    XX..XX   |
        CHART
      end

      it 'extends to a later due date to keep the same duration' do
        expect_schedule(subject.all_results, <<~CHART)
          days          | MTWTFSS      |
          work_package  |    XX..XX    |
          follower      |          XXX |
        CHART
        expect(follower.duration).to eq(3)
      end
    end

    context 'when predecessor moved forward' do
      context 'on a day in the middle on working days with the follower having only start date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS   |
          work_package  | X         |
          follower      |  [        | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  | XXXX    |
          CHART
        end

        it 'reschedules follower to start the next day after its predecessor due date' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  | XXXX      |
            follower      |     [     |
          CHART
        end
      end

      context 'on a day just before non working days with the follower having only start date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS   |
          work_package  | X         |
          follower      |  [        | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  | XXXXX   |
          CHART
        end

        it 'reschedules follower to start after the non working days' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  | XXXXX     |
            follower      |        [  |
          CHART
        end
      end

      context 'on a day in the middle of working days with the follower having only due date and no space in between' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | ]       |
          follower      |  ]      | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |    ]    |
          CHART
        end

        it 'reschedules follower to start and end right after its predecessor with a default duration of 1 day' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS |
            work_package  |    ]    |
            follower      |     X   |
          CHART
        end
      end

      context 'on a day in the middle of working days with the follower having only due date and much space in between' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSSmt |
          work_package  | ]         |
          follower      |         ] | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |    ]    |
          CHART
        end

        it 'reschedules follower to start after its predecessor without needing to change the end date' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          CHART
        end
      end

      context 'on a day just before non-working day with the follower having only due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | ]       |
          follower      |  ]      | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |     ]   |
          CHART
        end

        it 'reschedules follower to start and end after the non working days with a default duration of 1 day' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  |     ]     |
            follower      |        X  |
          CHART
        end
      end

      context 'with the follower having some space left' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS   |
          work_package  | X         |
          follower      |     X..XX  | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS   |
            work_package  | XXXXX     |
          CHART
        end

        it 'reschedules follower to start the next working day after its predecessor due date' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS     |
            work_package  | XXXXX       |
            follower      |        XXX  |
          CHART
        end
      end

      context 'with the follower having enough space left to not be moved at all' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS       |
          work_package  | X             |
          follower      |          XXX  | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS   |
            work_package  | XXXXX..X  |
          CHART
        end

        it 'does not move follower' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS       |
            work_package  | XXXXX..X      |
            follower      |          XXX  |
          CHART
        end
      end

      context 'with the follower having some space left and a delay' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSSmtwtfss  |
          work_package  | X               |
          follower      |        XXX      | follows work_package with delay 3
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS   |
            work_package  | XXXXX..X  |
          CHART
        end

        it 'reschedules the follower to start after the delay' do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSSmtwtfss   |
            work_package  | XXXXX..X         |
            follower      |            X..XX |
          CHART
        end
      end
    end

    context 'when predecessor moved backwards' do
      context 'on a day right before some non-working days' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | X       |
          follower      |  XX     | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          |    MTWTFSS |
            work_package  | X          |
          CHART
        end

        it 'reschedules the follower to start after the non-working days' do
          expect_schedule(subject.all_results, <<~CHART)
                          |    MTWTFSS |
            work_package  | X          |
            follower      |    XX      |
          CHART
        end
      end

      context 'on a day in the middle of working days' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | X       |
          follower      |  XX     | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
          CHART
        end

        it 'reschedules the follower to move by the same delta of working days' do
          expect_schedule(subject.all_results, <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
            follower      |   XX                  |
          CHART
        end
      end

      context 'on a day before non-working days the follower having space between' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS   |
          work_package  | X         |
          follower      |     X     | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          |    MTWTFSS |
            work_package  | X          |
          CHART
        end

        it 'reschedules follower to move backward by the same delta of working days' do
          expect_schedule(subject.all_results, <<~CHART)
                          |    MTWTFSS   |
            work_package  | X            |
            follower      |       X      |
          CHART
        end
      end

      context 'with the follower having another relation limiting movement' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | mtwtfssmtwtfssMTWTFSS |
          work_package  |               X       |
          follower      |                XX     | follows work_package, follows annoyer with delay 2
          annoyer       |    XX..XX             |
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X            _       |
          CHART
        end

        it 'reschedules follower to move backward but not earlier than the other relation soonest start date' do
          expect_schedule(subject.all_results, <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
            follower      |            X..X       |
          CHART
        end
      end

      context 'with the follower having another relation limiting movement and only due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | mtwtfssmtwtfssMTWTFSS |
          work_package  |               X       |
          follower      |                 ]     | follows work_package, follows annoyer with delay 2
          annoyer       |    XX..XX             |
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
          CHART
        end

        it 'reschedules follower to start at the other relation soonest start date and keep its end date' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
            follower      |            X..XXX     |
          CHART
        end
      end
    end

    context 'when removing the dates on the moved predecessor' do
      context 'with the follower having start and due dates' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |   XXX   | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
        end

        it 'does not reschedule and follower keeps its dates' do
          expect_schedule(subject.all_results, <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
            follower      |   XXX   |
          CHART
        end
      end

      context 'with the follower having only a due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |     ]   | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
        end

        it 'does not reschedule and follower keeps its dates' do
          expect_schedule(subject.all_results, <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
            follower      |     ]   |
          CHART
        end
      end
    end

    context 'when only creating the relation between predecessor and follower' do
      context 'with follower having no dates' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |         |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'schedules follower to start right after its predecessor and does not set the due date' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          CHART
        end
      end

      context 'with follower having only due date before predecessor due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          |    MTWTFSS |
          work_package  |    XX      |
          follower      | ]          |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'reschedules follower to start right after its predecessor and end the same day' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   X     |
          CHART
        end
      end

      context 'with follower having only start date before predecessor due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          |    MTWTFSS |
          work_package  |    XX      |
          follower      | [          |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'reschedules follower to start right after its predecessor and leaves the due date unset' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          CHART
        end
      end

      context 'with follower having both start and due dates before predecessor due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | mtwtfssMTWTFSS |
          work_package  |        XX      |
          follower      | XXXX           |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'reschedules follower to start right after its predecessor and keeps the duration' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS  |
            work_package  | XX       |
            follower      |   XXX..X |
          CHART
        end
      end

      context 'with follower having due date long after predecessor due date' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |     ]   |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'reschedules follower to start right after its predecessor and end the same day' do
          # TODO: is this correct? I would have expected this instead:
          # days          | MTWTFSS |
          # work_package  | XX      |
          # follower      |   XXX   |
          # Question sent to Niels to check if ok or not.
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   X     |
          CHART
        end
      end

      context 'with predecessor and follower having no dates' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days          | MTWTFSS |
          work_package  |         |
          follower      |         |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it 'does not reschedule any work package' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
        end
      end
    end

    context 'with the successor having another predecessor which has no dates' do
      context 'when moved forward' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days              | MTWTFSS |
          work_package      | ]       |
          follower          |  XXX    | follows work_package, follows other_predecessor
          other_predecessor |         |
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |    ]    |
          CHART
        end

        it 'reschedules follower without influence from the other predecessor' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          CHART
        end
      end

      context 'when moved backwards' do
        let_schedule(<<~CHART, ignore_non_working_days: false)
          days              | MTWTFSS |
          work_package      | ]       |
          follower          |  XXX    | follows work_package, follows other_predecessor
          other_predecessor |         |
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | mtwtfssMTWTFSS |
            work_package  |   ]            |
          CHART
        end

        it 'reschedules follower without influence from the other predecessor' do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | mtwtfssMTWTFSS |
            work_package  |   ]            |
            follower      |    XX..X       |
          CHART
        end
      end
    end
  end

  context 'with a parent' do
    context 'when setting both start and due dates' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days         | MTWTFSS |
        parent       |         |
        work_package | ]       | child of parent
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | mtwtfssMTWTFSS |
          work_package |   XXX..X       |
        CHART
      end

      it 'reschedules parent to have the same dates as the child' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | mtwtfssMTWTFSS |
          parent       |   XXX..X       |
          work_package |   XXX..X       |
        CHART
      end
    end
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
    #     follower1     |  XXX        | follows work_package
    #     follower2     |     XXXXX   | follows follower1
    #     follower3     |     XXXX    | follows work_package
    #     follower4     |          XX | follows follower2, after follower3
    #   CHART

    #   context 'when moving forward' do
    #     before do
    #       change_schedule(<<~CHART)
    #                       | MTWTFSS |
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
