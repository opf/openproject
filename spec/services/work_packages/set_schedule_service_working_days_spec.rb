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
      let_work_packages(<<~TABLE)
        subject       | MTWTFSS | scheduling mode | predecessors
        work_package  | XX      | manual          |
        follower      |   XXX   | automatic       | follows work_package
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject       | MTWTFSS |
          work_package  | XXXX    |
        TABLE
      end

      it "extends to a later due date to keep the same duration" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject       | MTWTFSS   |
          work_package  | XXXX      |
          follower      |     X..XX |
        TABLE
        expect(follower.duration).to eq(3)
      end
    end

    context "when moved predecessor covers non-working days" do
      let_work_packages(<<~TABLE)
        subject       | MTWTFSS      | scheduling mode | predecessors
        work_package  |    XX        | manual          |
        follower      |        XXX   | automatic       | follows work_package
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject       | MTWTFSS     |
          work_package  |    XX..XX   |
        TABLE
      end

      it "extends to a later due date to keep the same duration" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject       | MTWTFSS      |
          work_package  |    XX..XX    |
          follower      |          XXX |
        TABLE
        expect(follower.duration).to eq(3)
      end
    end

    context "when predecessor moved forward" do
      context "on a day in the middle on working days with the follower having only start date" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS   | scheduling mode | predecessors
          work_package  | X         | manual          |
          follower      |  [        | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XXXX    |
          TABLE
        end

        it "reschedules follower to start the next day after its predecessor due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  | XXXX      |
            follower      |     [     |
          TABLE
        end
      end

      context "on a day just before non working days with the follower having only start date" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS   | scheduling mode | predecessors
          work_package  | X         | manual          |
          follower      |  [        | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XXXXX   |
          TABLE
        end

        it "reschedules follower to start after the non working days" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  | XXXXX     |
            follower      |        [  |
          TABLE
        end
      end

      context "on a day in the middle of working days with the follower having only due date and no space in between" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | ]       | manual          |
          follower      |  ]      | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |    ]    |
          TABLE
        end

        it "reschedules follower to start and end right after its predecessor with a default duration of 1 day" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  |    ]    |
            follower      |     X   |
          TABLE
        end
      end

      context "on a day in the middle of working days with the follower having only due date and much space in between" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSSmt | scheduling mode | predecessors
          work_package  | ]         | manual          |
          follower      |         ] | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |    ]    |
          TABLE
        end

        it "reschedules follower to start after its predecessor without needing to change the end date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          TABLE
        end
      end

      context "on a day just before non-working day with the follower having only due date" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | ]       | manual          |
          follower      |  ]      | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |     ]   |
          TABLE
        end

        it "reschedules follower to start and end after the non working days with a default duration of 1 day" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  |     ]     |
            follower      |        X  |
          TABLE
        end
      end

      context "with the follower having some space left" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS   | scheduling mode | predecessors
          work_package  | X         | manual          |
          follower      |     X..XX | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS   |
            work_package  | XXXXX     |
          TABLE
        end

        it "reschedules follower to start the next working day after its predecessor due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS     |
            work_package  | XXXXX       |
            follower      |        XXX  |
          TABLE
        end
      end

      context "with the follower having enough space left to not be moved at all" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS       | scheduling mode | predecessors
          work_package  | X             | manual          |
          follower      |          XXX  | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS   |
            work_package  | XXXXX..X  |
          TABLE
        end

        it "moves follower to the soonest working day after its predecessor due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS       |
            work_package  | XXXXX..X      |
            follower      |         XXX   |
          TABLE
        end
      end

      context "with the follower having some space left and a lag" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSSmtwtfss  | scheduling mode | predecessors
          work_package  | X               | manual          |
          follower      |        XXX      | automatic       | follows work_package with lag 3
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS   |
            work_package  | XXXXX..X  |
          TABLE
        end

        it "reschedules the follower to start after the lag" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSSmtwtfss   |
            work_package  | XXXXX..X         |
            follower      |            X..XX |
          TABLE
        end
      end

      context "with the follower having a lag overlapping non-working days" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | X       | manual          |
          follower      |    XX   | automatic       | follows work_package with lag 2
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |     X   |
          TABLE
        end

        it "reschedules the follower to start after the non-working days and the lag" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSSmtwt |
            work_package  |     X       |
            follower      |          XX |
          TABLE
        end
      end
    end

    context "when predecessor moved backwards" do
      context "on a day right before some non-working days" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | X       | manual          |
          follower      |  XX     | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       |      MTWTFSS |
            work_package  | X            |
          TABLE
        end

        it "moves follower to the soonest working day after its predecessor due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       |      MTWTFSS |
            work_package  | X            |
            follower      |  XX          |
          TABLE
        end
      end

      context "on a day before non-working days the follower having space between" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS   | scheduling mode | predecessors
          work_package  | X         | manual          |
          follower      |     X     | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       |    MTWTFSS |
            work_package  | X          |
          TABLE
        end

        it "does not move the follower" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       |    MTWTFSS |
            work_package  | X          |
            follower      |    X       |
          TABLE
        end
      end

      context "with the follower having another relation limiting movement" do
        let_work_packages(<<~TABLE)
          subject       | mtwtfssmtwtfssMTWTFSS | scheduling mode | predecessors
          work_package  |               X       | manual          |
          follower      |                XX     | automatic       | follows work_package, follows annoyer with lag 2
          annoyer       |    XX..XX             | manual          |
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
          TABLE
        end

        it "does not move the follower" do
          expect_work_packages(subject.all_results + [annoyer], <<~TABLE)
            subject       | mtwtfssmtwtfssMTWTFSS |
            work_package  |  X                    |
            follower      |            X..X       |
            annoyer       |    XX..XX             |
          TABLE
        end
      end
    end

    context "when removing the dates on the moved predecessor" do
      context "with the follower having start and due dates" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | XX      | manual          |
          follower      |   XXX   | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |         |
          TABLE
        end

        it "does not reschedule and follower keeps its dates" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  |         |
          TABLE
          expect_work_packages([follower], <<~TABLE)
            subject       | MTWTFSS |
            follower      |   XXX   |
          TABLE
        end
      end

      context "with the follower having only a due date" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS | scheduling mode | predecessors
          work_package  | XX      | manual          |
          follower      |     ]   | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |         |
          TABLE
        end

        it "does not reschedule and follower keeps its dates" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  |         |
          TABLE
          expect_work_packages([follower], <<~TABLE)
            subject       | MTWTFSS |
            follower      |     ]   |
          TABLE
        end
      end
    end

    context "when only creating the relation between predecessor and follower" do
      context "with follower having no dates" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS |
          work_package  | XX      |
          follower      |         |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "schedules follower to start right after its predecessor and does not set the due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          TABLE
        end
      end

      context "with follower having only due date before predecessor due date" do
        let_work_packages(<<~TABLE)
          subject       |    MTWTFSS |
          work_package  |    XX      |
          follower      | ]          |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "reschedules follower to start right after its predecessor and end the same day" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XX      |
            follower      |   X     |
          TABLE
        end
      end

      context "with follower having only start date before predecessor due date" do
        let_work_packages(<<~TABLE)
          subject       |    MTWTFSS |
          work_package  |    XX      |
          follower      | [          |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "reschedules follower to start right after its predecessor and leaves the due date unset" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XX      |
            follower      |   [     |
          TABLE
        end
      end

      context "with follower having both start and due dates before predecessor due date" do
        let_work_packages(<<~TABLE)
          subject       |    mtwtfssMTWTFSS |
          work_package  |           XX      |
          follower      | X..XXX            |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "reschedules follower to start right after its predecessor and keeps the duration" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS  |
            work_package  | XX       |
            follower      |   XXX..X |
          TABLE
        end
      end

      context "with follower having due date long after predecessor due date" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS |
          work_package  | XX      |
          follower      |     ]   |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "reschedules follower to start right after its predecessor and end at the already defined due date" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  | XX      |
            follower      |   XXX   |
          TABLE
        end
      end

      context "with predecessor and follower having no dates" do
        let_work_packages(<<~TABLE)
          subject       | MTWTFSS |
          work_package  |         |
          follower      |         |
        TABLE

        before do
          create(:follows_relation, from: follower, to: work_package)
          follower.update_column(:schedule_manually, false)
        end

        it "does not reschedule any work package" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS |
            work_package  |         |
          TABLE
        end
      end
    end

    context "with the successor having another predecessor which has no dates" do
      context "when moved forward" do
        let_work_packages(<<~TABLE)
          subject           | MTWTFSS | scheduling mode | predecessors
          work_package      | ]       | manual          |
          follower          |  XXX    | automatic       | follows work_package, follows other_predecessor
          other_predecessor |         | manual          |
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |    ]    |
          TABLE
        end

        it "reschedules follower without influence from the other predecessor" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  |    ]      |
            follower      |     X..XX |
          TABLE
        end
      end

      context "when moved backwards" do
        let_work_packages(<<~TABLE)
          subject           | MTWTFSS | scheduling mode | predecessors
          work_package      | ]       | manual          |
          follower          |  XXX    | automatic       | follows work_package, follows other_predecessor
          other_predecessor |         | manual          |
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | mtwtfssMTWTFSS |
            work_package  |   ]            |
          TABLE
        end

        it "rescheduled follower to start as soon as possible without influence from the other predecessor" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | mtwtfssMTWTFSS |
            work_package  |   ]            |
            follower      |    XX..X       |
          TABLE
        end
      end
    end

    context "with successor having only duration" do
      context "when setting dates on predecessor" do
        let_work_packages(<<~TABLE)
          subject           | MTWTFSS | duration | scheduling mode | predecessors
          work_package      |         |          | manual          |
          follower          |         |        3 | automatic       | follows work_package
        TABLE

        before do
          change_work_packages([work_package], <<~TABLE)
            subject       | MTWTFSS |
            work_package  |   XX    |
          TABLE
        end

        it "schedules successor to start after predecessor and keeps the duration (#44479)" do
          expect_work_packages(subject.all_results, <<~TABLE)
            subject       | MTWTFSS   |
            work_package  |   XX      |
            follower      |     X..XX |
          TABLE
        end
      end
    end
  end

  context "with a parent" do
    let_work_packages(<<~TABLE)
      hierarchy      | MTWTFSS | scheduling mode
      parent         |         | automatic
        work_package | ]       | manual
    TABLE

    before do
      change_work_packages([work_package], <<~TABLE)
        subject      | mtwtfssMTWTFSS |
        work_package |   XXX..X       |
      TABLE
    end

    it "reschedules parent to have the same dates as the child" do
      expect_work_packages(subject.all_results, <<~TABLE)
        subject      | mtwtfssMTWTFSS |
        parent       |   XXX..X       |
        work_package |   XXX..X       |
      TABLE
    end
  end

  context "with a parent having a follower" do
    let_work_packages(<<~TABLE)
      hierarchy       | MTWTFSS   | scheduling mode | predecessors
      parent          | XX        | automatic       |
        work_package  | ]         | manual          |
      parent_follower |     X..XX | automatic       | follows parent
    TABLE

    before do
      change_work_packages([work_package], <<~TABLE)
        subject      | MTWTFSS |
        work_package | XXXXX   |
      TABLE
    end

    it "reschedules parent to have the same dates as the child, and parent follower to start right after parent" do
      expect_work_packages(subject.all_results, <<~TABLE)
        subject         | MTWTFSS    |
        parent          | XXXXX      |
        work_package    | XXXXX      |
        parent_follower |        XXX |
      TABLE
    end
  end

  context "with a predecessor and a child automatically scheduled" do
    let_work_packages(<<~TABLE)
      hierarchy    | MTWTFSS   | scheduling mode | predecessors
      predecessor  | XX        | manual          |
      work_package |   XX      | automatic       | predecessor
        child      |   XX      | automatic       |
    TABLE

    context "when switching to manual scheduling" do
      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | scheduling mode |
          work_package | manual          |
        TABLE
      end

      it "switches the child to manual scheduling too" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | scheduling mode |
          work_package | manual          |
          child        | manual          |
        TABLE
      end
    end
  end

  context "with a single successor having a parent" do
    context "when moving forward" do
      let_work_packages(<<~TABLE)
        hierarchy       | MTWTFSS | scheduling mode | predecessors
        work_package    | ]       | manual          |
        follower_parent |  XX     | automatic       |
          follower      |  XX     | automatic       | follows work_package
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules follower and follower parent to start right after the moved predecessor" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject         | MTWTFSS  |
          work_package    |    ]     |
          follower        |     X..X |
          follower_parent |     X..X |
        TABLE
      end
    end

    context "when moving forward with the parent having another child not being moved" do
      let_work_packages(<<~TABLE)
        hierarchy          | MTWTFSS | scheduling mode | predecessors
        work_package       | ]       | manual          |
        follower_parent    |  XXXX   | automatic       |
          follower         |  XX     | automatic       | follows work_package
          follower_sibling |   XXX   | manual          |
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules follower to start right after the moved predecessor, and follower parent spans on its two children" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject          | MTWTFSS  |
          work_package     |    ]     |
          follower_parent  |   XXX..X |
          follower         |     X..X |
        TABLE
        expect_work_packages([follower_sibling], <<~TABLE)
          subject          | MTWTFSS  |
          follower_sibling |   XXX    |
        TABLE
      end
    end

    context "when moving backwards" do
      let_work_packages(<<~TABLE)
        hierarchy       | MTWTFSS | scheduling mode | predecessors
        work_package    | ]       | manual          |
        follower_parent |  XX     | automatic       |
          follower      |  XX     | automatic       | follows work_package
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | mtwtfssMTWTFSS |
          work_package |    ]           |
        TABLE
      end

      it "reschedules follower and follower parent to start right after the moved predecessor" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject         | mtwtfssMTWTFSS |
          work_package    |    ]           |
          follower_parent |     X..X       |
          follower        |     X..X       |
        TABLE
      end
    end

    context "when moving backwards with the parent having another child not being moved" do
      let_work_packages(<<~TABLE)
        hierarchy          | mtwtfssMTWTFSS | scheduling mode | predecessors
        work_package       |        ]       | manual          |
        follower_parent    |         XXXX   | automatic       |
          follower         |         XX     | automatic       | follows work_package
          follower_sibling |          XXX   | manual          |
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | mtwtfssMTWTFSS |
          work_package |  ]             |
        TABLE
      end

      it "reschedules follower to start right after the moved predecessor, and follower parent spans on its two children" do
        expect_work_packages(subject.all_results + [follower_sibling], <<~TABLE)
          subject         | mtwtfssMTWTFSS |
          work_package    |  ]             |
          follower_parent |   XXX..XXXXX   |
          follower        |   XX           |
          follower_sibling|          XXX   |
        TABLE
      end
    end
  end

  context "with a single successor having a child in automatic scheduling mode" do
    context "when moving forward" do
      let_work_packages(<<~TABLE)
        hierarchy        | MTWTFSS | scheduling mode | predecessors
        work_package     | ]       | manual          |
        follower         |  XX     | automatic       | follows work_package
          follower_child |  XX     | automatic       |
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules follower and follower child to start right after the moved predecessor" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject        | MTWTFSS  |
          work_package   |    ]     |
          follower       |     X..X |
          follower_child |     X..X |
        TABLE
      end
    end
  end

  context "with a single successor having a child in manual scheduling mode" do
    context "when moving forward" do
      let_work_packages(<<~TABLE)
        hierarchy        | MTWTFSS | scheduling mode | predecessors
        work_package     | ]       | manual          |
        follower         |  XX     | automatic       | follows work_package
          follower_child |  XX     | manual          |
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "does not reschedule follower as dates depend on follower child which is manually scheduled" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject        | MTWTFSS  |
          work_package   |    ]     |
        TABLE
      end
    end
  end

  context "with a single successor having two children automatically scheduled" do
    context "when creating the follows relation while successor starts right after moved work package due date" do
      let_work_packages(<<~TABLE)
        hierarchy         | MTWTFSS          | scheduling mode | predecessors
        work_package      | ]                | manual          |
        follower          |  XXXX..XXXXX..XX | automatic       |
          follower_child1 |  XXX             | automatic       |
          follower_child2 |     X..XXXXX..XX | automatic       | follows follower_child1
      TABLE

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "does not need to reschedule anything" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS |
          work_package | ]       |
        TABLE
      end
    end

    context "when creating the follows relation while follower starts 3 days after moved due date" do
      let_work_packages(<<~TABLE)
        hierarchy         | MTWTFSS            | scheduling mode | predecessors
        work_package      | ]                  | manual          |
        follower          |    XX..XXXXX..XXXX | automatic       |
          follower_child1 |    XX..X           | automatic       |
          follower_child2 |         XXXX..XXXX | automatic       | follows follower_child1
      TABLE

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "reschedules followers to start right after the predecessor (moving backward)" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject         | MTWTFSS          |
          work_package    | ]                |
          follower        |  XXXX..XXXXX..XX |
          follower_child1 |  XXX             |
          follower_child2 |     X..XXXXX..XX |
        TABLE
      end
    end

    context "when creating the follows relation and follower first child starts before moved due date" do
      let_work_packages(<<~TABLE)
        hierarchy         |    MTWTFSS     | scheduling mode |
        work_package      |    ]           | manual          |
        follower          | X..XXXXX..XXXX | automatic       |
          follower_child1 | X..XXXX        | automatic       |
          follower_child2 |        X..XXXX | manual          |
      TABLE

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "reschedules first child and reduces follower parent duration as the children can be executed at the same time" do
        expect_work_packages(subject.all_results + [follower_child2], <<~TABLE)
          subject         | MTWTFSS     |
          work_package    | ]           |
          follower        |  XXXX..XXXX |
          follower_child1 |  XXXX..X    |
          follower_child2 |     X..XXXX |
        TABLE
      end
    end

    context "when creating the follows relation and both follower children start before moved due date" do
      let_work_packages(<<~TABLE)
        hierarchy         |      MTWTFSS  | scheduling mode |
        work_package      |      ]        | manual          |
        follower          | XXX..XXXXX..X | automatic       |
          follower_child1 | X             | automatic       |
          follower_child2 |   X..XXXXX..X | automatic       |
      TABLE

      before do
        create(:follows_relation, from: follower, to: work_package)
      end

      it "reschedules both children and reduces follower parent duration" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject           | MTWTFSS    |
          work_package      | ]          |
          follower          |  XXXX..XXX |
            follower_child1 |  X         |
            follower_child2 |  XXXX..XXX |
        TABLE
      end
    end
  end

  context "with a chain of followers" do
    context "when moving forward" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm     sm | scheduling mode | predecessors
        work_package | ]                      | manual          |
        follower1    |  XXX                   | automatic       | follows work_package
        follower2    |     X..XXXX            | automatic       | follows follower1
        follower3    |            X..XXXX     | automatic       | follows follower2
        follower4    |                   X..X | automatic       | follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules each follower forward by the same delta" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSSm     sm     sm    |
          work_package |    ]                      |
          follower1    |     X..XX                 |
          follower2    |          XXX..XX          |
          follower3    |                 XXXX..X   |
          follower4    |                        XX |
        TABLE
      end
    end

    context "when moving forward with some space between the followers" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm     sm     | scheduling mode | predecessors
        work_package | ]                          | manual          |
        follower1    |  XXX                       | automatic       | follows work_package
        follower2    |        XXXX                | automatic       | follows follower1
        follower3    |                 XXX..XX    | automatic       | follows follower2
        follower4    |                         XX | automatic       | follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules all followers to start as soon as possible" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSSm     sm     sm   |
          work_package |    ]                     |
          follower1    |     X..XX                |
          follower2    |          XXX..X          |
          follower3    |                XXXX..X   |
          follower4    |                       XX |
        TABLE
      end
    end

    context "when moving forward with some lag and spaces between the followers" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm     sm     | scheduling mode | predecessors
        work_package | ]                          | manual          |
        follower1    |  XXX                       | automatic       | follows work_package
        follower2    |        XXXX                | automatic       | follows follower1 with lag 3
        follower3    |                 XXX..XX    | automatic       | follows follower2
        follower4    |                         XX | automatic       | follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |    ]    |
        TABLE
      end

      it "reschedules all the followers keeping the lag and compacting the extra spaces" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSSm     sm     sm     sm |
          work_package |    ]                          |
          follower1    |     X..XX                     |
          follower2    |               XXXX            |
          follower3    |                   X..XXXX     |
          follower4    |                          X..X |
        TABLE
      end
    end

    context "when moving forward due to days and predecessor due date now being non-working days" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        work_package | XX      | manual          |
        follower1    |   X     | automatic       | follows work_package
        follower2    |    XX   | automatic       | follows follower1
      TABLE

      before do
        # Tuesday, Thursday, and Friday are now non-working days. So work_package
        # was starting on Monday and now is being shifted to Tuesday by the
        # SetAttributesService.
        #
        # Below instructions reproduce the conditions in which such scheduling
        # must happen.
        set_non_working_week_days("tuesday", "thursday", "friday")
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package | X.X     |
        TABLE
      end

      it "reschedules all the followers keeping the lag and compacting the extra spaces" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSSm w    m |
          work_package | X.X             |
          follower1    |        X        |
          follower2    |          X....X |
        TABLE
      end
    end

    context "when moving forward due to days and predecessor start date now being non-working days" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSS | scheduling mode | predecessors
        work_package | XX      | manual          |
        follower1    |   X     | automatic       | follows work_package
        follower2    |    XX   | automatic       | follows follower1
      TABLE

      before do
        # Monday, Thursday, and Friday are now non-working days. So work_package
        # was starting on Monday and now is being shifted to Tuesday by the
        # SetAttributesService.
        #
        # Below instructions reproduce the conditions in which such scheduling
        # must happen.
        set_non_working_week_days("monday", "thursday", "friday")
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |  XX     |
        TABLE
      end

      it "reschedules all the followers without crossing each other" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSS tw     tw |
          work_package |  XX               |
          follower1    |         X         |
          follower2    |          X.....X  |
        TABLE
      end
    end

    context "when moving backwards" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm     sm     | scheduling mode | predecessors
        work_package | ]                          | manual          |
        follower1    |  XXX                       | automatic       | follows work_package
        follower2    |     X..XXX                 | automatic       | follows follower1
        follower3    |                 XXX..XX    | automatic       | follows follower2
        follower4    |                         XX | automatic       | follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | m     sMTWTFSS |
          work_package |    ]           |
        TABLE
      end

      it "reschedules followers to start as soon as possible" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | m     sMTWTFSSm     sm   |
          work_package |    ]                     |
          follower1    |     X..XX                |
          follower2    |          XXX..X          |
          follower3    |                XXXX..X   |
          follower4    |                       XX |
        TABLE
      end
    end
  end

  context "with a chain of followers with two paths leading to the same follower in the end" do
    context "when moving forward" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm  | scheduling mode | predecessors
        work_package | ]                | manual          |
        follower1    |  XXX             | automatic       | follows work_package
        follower2    |     X..XXXX      | automatic       | follows follower1
        follower3    |    XX..X         | automatic       | follows work_package
        follower4    |            X..XX | automatic       | follows follower2, follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | MTWTFSS |
          work_package |     ]   |
        TABLE
      end

      it "reschedules followers while satisfying all constraints" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | MTWTFSSm     sm     sm |
          work_package |     ]                  |
          follower1    |        XXX             |
          follower2    |           XX..XXX      |
          follower3    |        XXX             |
          follower4    |                  XX..X |
        TABLE
      end
    end

    context "when moving backwards" do
      let_work_packages(<<~TABLE)
        subject      | MTWTFSSm     sm  | scheduling mode | predecessors
        work_package | ]                | manual          |
        follower1    |  XXX             | automatic       | follows work_package
        follower2    |     X..XXXX      | automatic       | follows follower1
        follower3    |    XX..X         | automatic       | follows work_package
        follower4    |            X..XX | automatic       | follows follower2, follows follower3
      TABLE

      before do
        change_work_packages([work_package], <<~TABLE)
          subject      | m     sMTWTFSS |
          work_package |   ]            |
        TABLE
      end

      it "reschedules followers to start as soon as possible while satisfying all constraints" do
        expect_work_packages(subject.all_results, <<~TABLE)
          subject      | m     sMTWTFSS     |
          work_package |   ]                |
          follower1    |    XX..X           |
          follower2    |         XXXX..X    |
          follower3    |    XX..X           |
          follower4    |                XXX |
        TABLE
      end
    end
  end
end
