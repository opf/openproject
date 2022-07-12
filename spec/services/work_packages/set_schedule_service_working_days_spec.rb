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
          days          |    mtwtfssMTWTFSS |
          work_package  |           XX      |
          follower      | X..XXX            |
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
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   XXX   |
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

  context 'with a parent having a follower' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days            | MTWTFSS   |
      parent          | XX        |
      work_package    | ]         | child of parent
      parent_follower |     X..XX | follows parent
    CHART

    before do
      change_schedule([work_package], <<~CHART)
        days         | MTWTFSS |
        work_package | XXXXX   |
      CHART
    end

    it 'reschedules parent to have the same dates as the child, and parent follower to start right after parent' do
      expect(subject.all_results).to match_schedule(<<~CHART)
        days            | MTWTFSS    |
        parent          | XXXXX      |
        work_package    | XXXXX      |
        parent_follower |        XXX |
      CHART
    end
  end

  context 'with a single successor having a parent' do
    context 'when moving forward' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            | MTWTFSS |
        work_package    | ]       |
        follower        |  XX     | follows work_package, child of follower_parent
        follower_parent |  XX     |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it 'reschedules follower and follower parent to start right after the moved predecessor' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS  |
          work_package    |    ]     |
          follower        |     X..X |
          follower_parent |     X..X |
        CHART
      end
    end

    context 'when moving forward with the parent having another child not being moved' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days             | MTWTFSS |
        work_package     | ]       |
        follower         |  XX     | follows work_package, child of follower_parent
        follower_sibling |   XXX   | child of follower_parent
        follower_parent  |  XXXX   |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it 'reschedules follower to start right after the moved predecessor, and follower parent spans on its two children' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS  |
          work_package    |    ]     |
          follower        |     X..X |
          follower_parent |   XXX..X |
        CHART
      end
    end

    context 'when moving backwards' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            | MTWTFSS |
        work_package    | ]       |
        follower        |  XX     | follows work_package, child of follower_parent
        follower_parent |  XX     |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | mtwtfssMTWTFSS |
          work_package |    ]           |
        CHART
      end

      it 'reschedules follower and follower parent to start right after the moved predecessor' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |    ]           |
          follower        |     X..X       |
          follower_parent |     X..X       |
        CHART
      end
    end

    context 'when moving backwards with the parent having a predecessor not limiting movement' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days             | mtwtfssMTWTFSS |
        work_package     |        ]       |
        follower         |         XX     | follows work_package, child of follower_parent
        follower_parent  |         XX     | follows predecessor with delay 2
        predecessor      |  XX            |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | mtwtfssMTWTFSS |
          work_package |   ]            |
        CHART
      end

      it 'constraints follower and follower parent to start after the predecessor limiting movement' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |   ]            |
          follower        |        XX      |
          follower_parent |        XX      |
        CHART
      end
    end

    context 'when moving backwards with the parent having another relation not limiting movement' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days             |     mtwtfssMTWTFSS |
        work_package     |            ]       |
        follower         |             XXXX   | follows work_package, child of follower_parent
        follower_parent  |             XXXX   | follows predecessor with delay 2
        predecessor      | XX                 |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | mtwtfssMTWTFSS |
          work_package |  ]             |
        CHART
      end

      it 'reschedules follower and follower parent to start right after the moved predecessor' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |  ]             |
          follower        |   XXX..X       |
          follower_parent |   XXX..X       |
        CHART
      end
    end

    context 'when moving backwards with the parent having another child not being moved' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days             | mtwtfssMTWTFSS |
        work_package     |        ]       |
        follower         |         XX     | follows work_package, child of follower_parent
        follower_sibling |          XXX   | child of follower_parent
        follower_parent  |         XXXX   |
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | mtwtfssMTWTFSS |
          work_package |  ]             |
        CHART
      end

      it 'reschedules follower to start right after the moved predecessor, and follower parent spans on its two children' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |  ]             |
          follower        |   XX           |
          follower_parent |   XXX..XXXXX   |
        CHART
      end
    end
  end

  context 'with a single successor having a child' do
    context 'when moving forward' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days           | MTWTFSS |
        work_package   | ]       |
        follower       |  XX     | follows work_package
        follower_child |  XX     | child of follower
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it 'reschedules follower and follower child to start right after the moved predecessor' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days           | MTWTFSS  |
          work_package   |    ]     |
          follower       |     X..X |
          follower_child |     X..X |
        CHART
      end
    end
  end

  context 'with a single successor having two children' do
    context 'when creating the follows relation while follower starts 1 day after moved due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            | MTWTFSS          |
        work_package    | ]                |
        follower        |  XXXX..XXXXX..XX |
        follower_child1 |  XXX             | child of follower
        follower_child2 |            X..XX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it 'does not need to reschedule anything' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS |
          work_package | ]       |
        CHART
      end
    end

    context 'when creating the follows relation while follower starts 3 days after moved due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            | MTWTFSS            |
        work_package    | ]                  |
        follower        |    XX..XXXXX..XXXX |
        follower_child1 |    XX..X           | child of follower
        follower_child2 |                XXX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it 'does not need to reschedule anything' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS |
          work_package | ]       |
        CHART
      end
    end

    context 'when creating the follows relation and follower first child starts before moved due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            |    MTWTFSS     |
        work_package    |    ]           |
        follower        | X..XXXXX..XXXX |
        follower_child1 | X..XXXX        | child of follower
        follower_child2 |        X..XXXX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it 'reschedules first child and reduces follower parent duration as the children can be executed at the same time' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS     |
          work_package    | ]           |
          follower        |  XXXX..XXXX |
          follower_child1 |  XXXX..X    |
        CHART
      end
    end

    context 'when creating the follows relation and both follower children start before moved due date' do
      let_schedule(<<~CHART, ignore_non_working_days: false)
        days            |      MTWTFSS  |
        work_package    |      ]        |
        follower        | XXX..XXXXX..X |
        follower_child1 | X             | child of follower
        follower_child2 |   X..XXXXX..X | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it 'reschedules both children and reduces follower parent duration' do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS    |
          work_package    | ]          |
          follower        |  XXXX..XXX |
          follower_child1 |  X         | child of follower
          follower_child2 |  XXXX..XXX | child of follower
        CHART
      end
    end

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
