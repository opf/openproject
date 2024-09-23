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

RSpec.describe WorkPackages::SetScheduleService, "working days" do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:instance) do
    described_class.new(user:, work_package:)
  end
  let(:changed_attributes) { [:start_date] }

  subject { instance.call(changed_attributes) }

  context "with a single successor" do
    context "when moving successor will cover non-working days" do
      let_schedule(<<~CHART)
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

      it "extends to a later due date to keep the same duration" do
        expect_schedule(subject.all_results, <<~CHART)
          days          | MTWTFSS   |
          work_package  | XXXX      |
          follower      |     X..XX |
        CHART
        expect(follower.duration).to eq(3)
      end
    end

    context "when moved predecessor covers non-working days" do
      let_schedule(<<~CHART)
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

      it "extends to a later due date to keep the same duration" do
        expect_schedule(subject.all_results, <<~CHART)
          days          | MTWTFSS      |
          work_package  |    XX..XX    |
          follower      |          XXX |
        CHART
        expect(follower.duration).to eq(3)
      end
    end

    context "when predecessor moved forward" do
      context "on a day in the middle on working days with the follower having only start date" do
        let_schedule(<<~CHART)
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

        it "reschedules follower to start the next day after its predecessor due date" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  | XXXX      |
            follower      |     [     |
          CHART
        end
      end

      context "on a day just before non working days with the follower having only start date" do
        let_schedule(<<~CHART)
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

        it "reschedules follower to start after the non working days" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  | XXXXX     |
            follower      |        [  |
          CHART
        end
      end

      context "on a day in the middle of working days with the follower having only due date and no space in between" do
        let_schedule(<<~CHART)
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

        it "reschedules follower to start and end right after its predecessor with a default duration of 1 day" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS |
            work_package  |    ]    |
            follower      |     X   |
          CHART
        end
      end

      context "on a day in the middle of working days with the follower having only due date and much space in between" do
        let_schedule(<<~CHART)
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

        it "reschedules follower to start after its predecessor without needing to change the end date" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          CHART
        end
      end

      context "on a day just before non-working day with the follower having only due date" do
        let_schedule(<<~CHART)
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

        it "reschedules follower to start and end after the non working days with a default duration of 1 day" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS   |
            work_package  |     ]     |
            follower      |        X  |
          CHART
        end
      end

      context "with the follower having some space left" do
        let_schedule(<<~CHART)
          days          | MTWTFSS   |
          work_package  | X         |
          follower      |     X..XX | follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS   |
            work_package  | XXXXX     |
          CHART
        end

        it "reschedules follower to start the next working day after its predecessor due date" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS     |
            work_package  | XXXXX       |
            follower      |        XXX  |
          CHART
        end
      end

      context "with the follower having enough space left to not be moved at all" do
        let_schedule(<<~CHART)
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

        it "does not move follower" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSS       |
            work_package  | XXXXX..X      |
          CHART
          expect_schedule([follower], <<~CHART)
                          | MTWTFSS       |
            follower      |          XXX  |
          CHART
        end
      end

      context "with the follower having some space left and a lag" do
        let_schedule(<<~CHART)
          days          | MTWTFSSmtwtfss  |
          work_package  | X               |
          follower      |        XXX      | follows work_package with lag 3
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS   |
            work_package  | XXXXX..X  |
          CHART
        end

        it "reschedules the follower to start after the lag" do
          expect_schedule(subject.all_results, <<~CHART)
                          | MTWTFSSmtwtfss   |
            work_package  | XXXXX..X         |
            follower      |            X..XX |
          CHART
        end
      end

      context "with the follower having a lag overlapping non-working days" do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | X       |
          follower      |    XX   | follows work_package with lag 2
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |     X   |
          CHART
        end

        it "reschedules the follower to start after the non-working days and the lag" do
          expect(subject.all_results).to match_schedule(<<~CHART)
                          | MTWTFSSmtwt |
            work_package  |     X       |
            follower      |          XX |
          CHART
        end
      end
    end

    context "when predecessor moved backwards" do
      context "on a day right before some non-working days" do
        let_schedule(<<~CHART)
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

        it "does not move the follower" do
          expect(subject.all_results).to match_schedule(<<~CHART)
                          |    MTWTFSS |
            work_package  | X          |
          CHART
        end
      end

      context "on a day before non-working days the follower having space between" do
        let_schedule(<<~CHART)
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

        it "does not move the follower" do
          expect(subject.all_results).to match_schedule(<<~CHART)
                          |    MTWTFSS   |
            work_package  | X            |
          CHART
        end
      end

      context "with the follower having another relation limiting movement" do
        let_schedule(<<~CHART)
          days          | mtwtfssmtwtfssMTWTFSS |
          work_package  |               X       |
          follower      |                XX     | follows work_package, follows annoyer with lag 2
          annoyer       |    XX..XX             |
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
          CHART
        end

        it "does not move the follower" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
          CHART
        end
      end
    end

    context "when removing the dates on the moved predecessor" do
      context "with the follower having start and due dates" do
        let_schedule(<<~CHART)
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

        it "does not reschedule and follower keeps its dates" do
          expect_schedule(subject.all_results, <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
          expect_schedule([follower], <<~CHART)
            days          | MTWTFSS |
            follower      |   XXX   |
          CHART
        end
      end

      context "with the follower having only a due date" do
        let_schedule(<<~CHART)
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

        it "does not reschedule and follower keeps its dates" do
          expect_schedule(subject.all_results, <<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
          expect_schedule([follower], <<~CHART)
            days          | MTWTFSS |
            follower      |     ]   |
          CHART
        end
      end
    end

    context "when only creating the relation between predecessor and follower" do
      context "with follower having no dates" do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |         |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "schedules follower to start right after its predecessor and does not set the due date" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          CHART
        end
      end

      context "with follower having only due date before predecessor due date" do
        let_schedule(<<~CHART)
          days          |    MTWTFSS |
          work_package  |    XX      |
          follower      | ]          |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "reschedules follower to start right after its predecessor and end the same day" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   X     |
          CHART
        end
      end

      context "with follower having only start date before predecessor due date" do
        let_schedule(<<~CHART)
          days          |    MTWTFSS |
          work_package  |    XX      |
          follower      | [          |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "reschedules follower to start right after its predecessor and leaves the due date unset" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          CHART
        end
      end

      context "with follower having both start and due dates before predecessor due date" do
        let_schedule(<<~CHART)
          days          |    mtwtfssMTWTFSS |
          work_package  |           XX      |
          follower      | X..XXX            |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "reschedules follower to start right after its predecessor and keeps the duration" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS  |
            work_package  | XX       |
            follower      |   XXX..X |
          CHART
        end
      end

      context "with follower having due date long after predecessor due date" do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  | XX      |
          follower      |     ]   |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "reschedules follower to start right after its predecessor and end the same day" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  | XX      |
            follower      |   XXX   |
          CHART
        end
      end

      context "with predecessor and follower having no dates" do
        let_schedule(<<~CHART)
          days          | MTWTFSS |
          work_package  |         |
          follower      |         |
        CHART

        before do
          create(:follows_relation, from: follower, to: work_package)
        end

        it "does not reschedule any work package" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS |
            work_package  |         |
          CHART
        end
      end
    end

    context "with the successor having another predecessor which has no dates" do
      context "when moved forward" do
        let_schedule(<<~CHART)
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

        it "reschedules follower without influence from the other predecessor" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          CHART
        end
      end

      context "when moved backwards" do
        let_schedule(<<~CHART)
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

        it "does not move the follower" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | mtwtfssMTWTFSS |
            work_package  |   ]            |
          CHART
        end
      end
    end

    context "with successor having only duration" do
      context "when setting dates on predecessor" do
        let_schedule(<<~CHART)
          days              | MTWTFSS |
          work_package      |         |
          follower          |         | duration 3, follows work_package
        CHART

        before do
          change_schedule([work_package], <<~CHART)
            days          | MTWTFSS |
            work_package  |   XX    |
          CHART
        end

        it "schedules successor to start after predecessor and keeps the duration (#44479)" do
          expect(subject.all_results).to match_schedule(<<~CHART)
            days          | MTWTFSS   |
            work_package  |   XX      |
            follower      |     X..XX |
          CHART
        end
      end
    end
  end

  context "with a parent" do
    let_schedule(<<~CHART)
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

    it "reschedules parent to have the same dates as the child" do
      expect(subject.all_results).to match_schedule(<<~CHART)
        days         | mtwtfssMTWTFSS |
        parent       |   XXX..X       |
        work_package |   XXX..X       |
      CHART
    end
  end

  context "with a parent having a follower" do
    let_schedule(<<~CHART)
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

    it "reschedules parent to have the same dates as the child, and parent follower to start right after parent" do
      expect(subject.all_results).to match_schedule(<<~CHART)
        days            | MTWTFSS    |
        parent          | XXXXX      |
        work_package    | XXXXX      |
        parent_follower |        XXX |
      CHART
    end
  end

  context "with a single successor having a parent" do
    context "when moving forward" do
      let_schedule(<<~CHART)
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

      it "reschedules follower and follower parent to start right after the moved predecessor" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS  |
          work_package    |    ]     |
          follower        |     X..X |
          follower_parent |     X..X |
        CHART
      end
    end

    context "when moving forward with the parent having another child not being moved" do
      let_schedule(<<~CHART)
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

      it "reschedules follower to start right after the moved predecessor, and follower parent spans on its two children" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS  |
          work_package    |    ]     |
          follower        |     X..X |
          follower_parent |   XXX..X |
        CHART
      end
    end

    context "when moving backwards" do
      let_schedule(<<~CHART)
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

      it "does not reschedule the followers" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |    ]           |
        CHART
      end
    end

    context "when moving backwards with the parent having another child not being moved" do
      let_schedule(<<~CHART)
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

      it "does not rechedule the followers or the other child" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | mtwtfssMTWTFSS |
          work_package    |  ]             |
        CHART
      end
    end
  end

  context "with a single successor having a child" do
    context "when moving forward" do
      let_schedule(<<~CHART)
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

      it "reschedules follower and follower child to start right after the moved predecessor" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days           | MTWTFSS  |
          work_package   |    ]     |
          follower       |     X..X |
          follower_child |     X..X |
        CHART
      end
    end
  end

  context "with a single successor having two children" do
    context "when creating the follows relation while follower starts 1 day after moved due date" do
      let_schedule(<<~CHART)
        days            | MTWTFSS          |
        work_package    | ]                |
        follower        |  XXXX..XXXXX..XX |
        follower_child1 |  XXX             | child of follower
        follower_child2 |            X..XX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "does not need to reschedule anything" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS |
          work_package | ]       |
        CHART
      end
    end

    context "when creating the follows relation while follower starts 3 days after moved due date" do
      let_schedule(<<~CHART)
        days            | MTWTFSS            |
        work_package    | ]                  |
        follower        |    XX..XXXXX..XXXX |
        follower_child1 |    XX..X           | child of follower
        follower_child2 |                XXX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "does not need to reschedule anything" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS |
          work_package | ]       |
        CHART
      end
    end

    context "when creating the follows relation and follower first child starts before moved due date" do
      let_schedule(<<~CHART)
        days            |    MTWTFSS     |
        work_package    |    ]           |
        follower        | X..XXXXX..XXXX |
        follower_child1 | X..XXXX        | child of follower
        follower_child2 |        X..XXXX | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "reschedules first child and reduces follower parent duration as the children can be executed at the same time" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS     |
          work_package    | ]           |
          follower        |  XXXX..XXXX |
          follower_child1 |  XXXX..X    |
        CHART
      end
    end

    context "when creating the follows relation and both follower children start before moved due date" do
      let_schedule(<<~CHART)
        days            |      MTWTFSS  |
        work_package    |      ]        |
        follower        | XXX..XXXXX..X |
        follower_child1 | X             | child of follower
        follower_child2 |   X..XXXXX..X | child of follower
      CHART

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "reschedules both children and reduces follower parent duration" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days            | MTWTFSS    |
          work_package    | ]          |
          follower        |  XXXX..XXX |
          follower_child1 |  X         | child of follower
          follower_child2 |  XXXX..XXX | child of follower
        CHART
      end
    end
  end

  context "with a chain of followers" do
    context "when moving forward" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm     sm |
        work_package | ]                      |
        follower1    |  XXX                   | follows work_package
        follower2    |     X..XXXX            | follows follower1
        follower3    |            X..XXXX     | follows follower2
        follower4    |                   X..X | follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it "reschedules each follower forward by the same delta" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSSm     sm     sm    |
          work_package |    ]                      |
          follower1    |     X..XX                 | follows work_package
          follower2    |          XXX..XX          | follows follower1
          follower3    |                 XXXX..X   | follows follower2
          follower4    |                        XX | follows follower3
        CHART
      end
    end

    context "when moving forward with some space between the followers" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm     sm     |
        work_package | ]                          |
        follower1    |  XXX                       | follows work_package
        follower2    |        XXXX                | follows follower1
        follower3    |                 XXX..XX    | follows follower2
        follower4    |                         XX | follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it "reschedules only the first followers as the others don't need to move" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSSm     sm |
          work_package |    ]            |
          follower1    |     X..XX       |
          follower2    |          XXX..X |
        CHART
      end
    end

    context "when moving forward with some lag and spaces between the followers" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm     sm     |
        work_package | ]                          |
        follower1    |  XXX                       | follows work_package
        follower2    |        XXXX                | follows follower1 with lag 3
        follower3    |                 XXX..XX    | follows follower2
        follower4    |                         XX | follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |    ]    |
        CHART
      end

      it "reschedules all the followers keeping the lag and compacting the extra spaces" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSSm     sm     sm     sm |
          work_package |    ]                          |
          follower1    |     X..XX                     |
          follower2    |               XXXX            |
          follower3    |                   X..XXXX     |
          follower4    |                          X..X |
        CHART
      end
    end

    context "when moving forward due to days and predecessor due date now being non-working days" do
      let_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XX      |
        follower1    |   X     | follows work_package
        follower2    |    XX   | follows follower1
      CHART

      before do
        # Tuesday, Thursday, and Friday are now non-working days. So work_package
        # was starting on Monday and now is being shifted to Tuesday by the
        # SetAttributesService.
        #
        # Below instructions reproduce the conditions in which such scheduling
        # must happen.
        set_non_working_week_days("tuesday", "thursday", "friday")
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package | X.X     |
        CHART
      end

      it "reschedules all the followers keeping the lag and compacting the extra spaces" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSSm w    m |
          work_package | X.X             |
          follower1    |        X        |
          follower2    |          X....X |
        CHART
      end
    end

    context "when moving forward due to days and predecessor start date now being non-working days" do
      let_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XX      |
        follower1    |   X     | follows work_package
        follower2    |    XX   | follows follower1
      CHART

      before do
        # Monday, Thursday, and Friday are now non-working days. So work_package
        # was starting on Monday and now is being shifted to Tuesday by the
        # SetAttributesService.
        #
        # Below instructions reproduce the conditions in which such scheduling
        # must happen.
        set_non_working_week_days("monday", "thursday", "friday")
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |  XX     |
        CHART
      end

      it "reschedules all the followers without crossing each other" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS tw     tw |
          work_package |  XX               |
          follower1    |         X         |
          follower2    |          X.....X  |
        CHART
      end
    end

    context "when moving backwards" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm     sm     |
        work_package | ]                          |
        follower1    |  XXX                       | follows work_package
        follower2    |     X..XXX                 | follows follower1
        follower3    |                 XXX..XX    | follows follower2
        follower4    |                         XX | follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | m     sMTWTFSS |
          work_package |    ]           |
        CHART
      end

      it "does not reschedule any followers" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | m     sMTWTFSS |
          work_package |    ]           |
        CHART
      end
    end
  end

  context "with a chain of followers with two paths leading to the same follower in the end" do
    context "when moving forward" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm  |
        work_package | ]                |
        follower1    |  XXX             | follows work_package
        follower2    |     X..XXXX      | follows follower1
        follower3    |    XX..X         | follows work_package
        follower4    |            X..XX | follows follower2, follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | MTWTFSS |
          work_package |     ]   |
        CHART
      end

      it "reschedules followers while satisfying all constraints" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSSm     sm     sm |
          work_package |     ]                  |
          follower1    |        XXX             |
          follower2    |           XX..XXX      |
          follower3    |        XXX             |
          follower4    |                  XX..X |
        CHART
      end
    end

    context "when moving backwards" do
      let_schedule(<<~CHART)
        days         | MTWTFSSm     sm  |
        work_package | ]                |
        follower1    |  XXX             | follows work_package
        follower2    |     X..XXXX      | follows follower1
        follower3    |    XX..X         | follows work_package
        follower4    |            X..XX | follows follower2, follows follower3
      CHART

      before do
        change_schedule([work_package], <<~CHART)
          days         | m     sMTWTFSS |
          work_package |   ]            |
        CHART
      end

      it "does not reschedule any followers" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | m     sMTWTFSS |
          work_package |   ]            |
        CHART
      end
    end
  end

  context "when setting the parent" do
    let(:changed_attributes) { [:parent] }

    context "without dates and with the parent being restricted in its ability to be moved" do
      let_schedule(<<~CHART)
        days                   | MTWTFSS |
        work_package           |         |
        new_parent             |         | follows new_parent_predecessor with lag 3
        new_parent_predecessor |   X     |
      CHART

      before do
        work_package.parent = new_parent
        work_package.save
      end

      it "schedules parent to start and end at soonest working start date and the child to start at the parent start" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS   |
          work_package |         [ |
          new_parent   |         X |
        CHART
      end
    end

    context "without dates, with a duration and with the parent being restricted in its ability to be moved" do
      let_schedule(<<~CHART)
        days                   | MTWTFSS |
        work_package           |         | duration 4
        new_parent             |         | follows new_parent_predecessor with lag 3
        new_parent_predecessor |   X     |
      CHART

      before do
        work_package.parent = new_parent
        work_package.save
      end

      it "schedules the moved work package to start at the parent soonest date and sets due date to keep the same duration " \
         "and schedules the parent dates to match the child dates" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS      |
          work_package |         XXXX |
          new_parent   |         XXXX |
        CHART
      end
    end

    context "with the parent being restricted in its ability to be moved and with a due date before parent constraint" do
      let_schedule(<<~CHART)
        days                   | MTWTFSS   |
        work_package           | ]         |
        new_parent             |           | follows new_parent_predecessor with lag 3
        new_parent_predecessor | X         |
      CHART

      before do
        work_package.parent = new_parent
        work_package.save
      end

      it "schedules the moved work package to start and end at the parent soonest working start date" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS |
          work_package |     X   |
          new_parent   |     X   |
        CHART
      end
    end

    context "with the parent being restricted in its ability to be moved and with a due date after parent constraint" do
      let_schedule(<<~CHART)
        days                   | MTWTFSS   |
        work_package           |         ] |
        new_parent             |           | follows new_parent_predecessor with lag 3
        new_parent_predecessor | X         |
      CHART

      before do
        work_package.parent = new_parent
        work_package.save
      end

      it "schedules the moved work package to start at the parent soonest working start date and keep the due date" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS   |
          work_package |     X..XX |
          new_parent   |     X..XX |
        CHART
      end
    end

    context "with the parent being restricted but work package already has both dates set" do
      let_schedule(<<~CHART)
        days                   | MTWTFSS   |
        work_package           |        XX |
        new_parent             |           | follows new_parent_predecessor with lag 3
        new_parent_predecessor | X         |
      CHART

      before do
        work_package.parent = new_parent
        work_package.save
      end

      it "does not reschedule the moved work package, and sets new parent dates to child dates" do
        expect(subject.all_results).to match_schedule(<<~CHART)
          days         | MTWTFSS   |
          work_package |        XX |
          new_parent   |        XX |
        CHART
      end
    end
  end
end
