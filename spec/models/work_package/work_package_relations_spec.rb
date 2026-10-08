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

RSpec.describe WorkPackage do
  create_shared_association_defaults_for_work_package_factory

  describe "#relation" do
    let(:closed_state) do
      create(:status,
             category: "closed")
    end

    describe "#duplicate" do
      let(:status) { create(:status) }
      let(:type) { create(:type) }
      let(:original) do
        create(:work_package,
               project:,
               type:,
               status:)
      end
      let(:project) { create(:project, members: { current_user => workflow.role }) }
      let(:dup_1) do
        create(:work_package,
               project:,
               type:,
               status:)
      end
      let(:relation_org_dup_1) do
        create(:relation,
               from: dup_1,
               to: original,
               relation_type: Relation::TYPE_DUPLICATES)
      end
      let(:workflow) do
        create(:workflow,
               old_status: status,
               new_status: closed_state,
               type_id: type.id)
      end

      current_user { create(:user) }

      context "closes duplicates" do
        let(:dup_2) do
          create(:work_package,
                 project:,
                 type:,
                 status:)
        end
        let(:relation_dup_1_dup_2) do
          create(:relation,
                 from: dup_2,
                 to: dup_1,
                 relation_type: Relation::TYPE_DUPLICATES)
        end
        # circular dependency
        let(:relation_dup_2_org) do
          create(:relation,
                 from: dup_2,
                 to: original,
                 relation_type: Relation::TYPE_DUPLICATES)
        end

        before do
          relation_org_dup_1
          relation_dup_1_dup_2
          relation_dup_2_org

          original.status = closed_state
          original.save!

          dup_1.reload
          dup_2.reload
        end

        it "only duplicates are closed" do
          expect(dup_1).to be_closed
          expect(dup_2).to be_closed
        end
      end

      context "duplicated is not closed" do
        before do
          relation_org_dup_1

          dup_1.status = closed_state
          dup_1.save!

          original.reload
        end

        subject { original.closed? }

        it { is_expected.to be_falsey }
      end
    end

    describe "#soonest_start" do
      let(:predecessor) do
        create(:work_package,
               subject: "predecessor",
               due_date: predecessor_due_date)
      end
      let(:predecessor_due_date) { nil }
      let(:successor) do
        create(:work_package,
               subject: "successor",
               schedule_manually: successor_schedule_manually,
               ignore_non_working_days: successor_ignore_non_working_days)
      end
      let(:successor_schedule_manually) { false }
      let(:successor_ignore_non_working_days) { false }
      let(:successor_child) do
        create(:work_package,
               subject: "successor_child",
               schedule_manually: successor_child_schedule_manually,
               parent: successor)
      end
      let(:successor_child_schedule_manually) { false }
      let(:successor_grandchild) do
        create(:work_package,
               subject: "successor_grandchild",
               parent: successor_child)
      end
      let(:relation_successor) do
        create(:relation,
               from: predecessor,
               to: successor,
               lag: relation_lag,
               relation_type: Relation::TYPE_PRECEDES)
      end
      let(:relation_lag) { 0 }
      let(:work_packages) { [predecessor, successor, successor_child] }
      let(:relations) { [relation_successor] }

      before do
        work_packages
        relations
      end

      context "without a predecessor" do
        let(:work_packages) { [successor] }
        let(:relations) { [] }

        it { expect(successor.soonest_start).to be_nil }
      end

      context "with a predecessor" do
        let(:work_packages) { [predecessor, successor] }

        context "with a due date" do
          let(:predecessor_due_date) { Date.current }

          it { expect(successor.soonest_start).to eq(predecessor.due_date + 1) }
        end

        context "without dates" do
          it { expect(successor.soonest_start).to be_nil }
        end

        context "with non-working weekends" do
          shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

          let(:monday) { Date.current.monday }
          let(:thursday) { monday + 3.days }
          let(:friday) { monday + 4.days }
          let(:saturday) { monday + 5.days }
          let(:next_monday) { monday + 7.days }
          let(:next_tuesday) { monday + 8.days }

          context "if predecessor ends on Thursday, lag is 2 days " \
                  "and successor has 'Working days only' active" do
            let(:successor_ignore_non_working_days) { false }
            let(:relation_lag) { 2 }
            let(:predecessor_due_date) { thursday }

            it "returns next Tuesday to have 2 working days in between (Friday and Monday) " \
               "as Saturday and Sunday are non-working days" do
              expect(successor.soonest_start).to eq(next_tuesday)
            end
          end

          context "if predecessor ends on Thursday, lag is 2 days " \
                  "and successor has 'Working days only' inactive" do
            let(:successor_ignore_non_working_days) { true }
            let(:relation_lag) { 2 }
            let(:predecessor_due_date) { thursday }

            it "returns next Tuesday to have 2 working days in between (Friday and Monday)" do
              expect(successor.soonest_start).to eq(next_tuesday)
            end
          end

          context "if predecessor ends on Thursday, lag is 1 day " \
                  "and successor has 'Working days only' active" do
            let(:successor_ignore_non_working_days) { false }
            let(:relation_lag) { 1 }
            let(:predecessor_due_date) { thursday }

            it "returns next Monday to have 1 working day in between (Friday) " \
               "as Saturday or Sunday are non-working days" do
              expect(successor.soonest_start).to eq(next_monday)
            end
          end

          context "if predecessor ends on Thursday, lag is 1 day " \
                  "and successor has 'Working days only' inactive" do
            let(:successor_ignore_non_working_days) { true }
            let(:relation_lag) { 1 }
            let(:predecessor_due_date) { thursday }

            it "returns Saturday to have 1 working day in between (Friday)" do
              expect(successor.soonest_start).to eq(saturday)
            end
          end

          context "if predecessor ends on Friday, lag is 0 days " \
                  "and successor has 'Working days only' active" do
            let(:successor_ignore_non_working_days) { false }
            let(:relation_lag) { 0 }
            let(:predecessor_due_date) { friday }

            it "returns next Monday as Saturday and Sunday are non-working days" do
              expect(successor.soonest_start).to eq(next_monday)
            end
          end

          context "if predecessor ends on Friday, lag is 0 days " \
                  "and successor has 'Working days only' inactive" do
            let(:successor_ignore_non_working_days) { true }
            let(:relation_lag) { 0 }
            let(:predecessor_due_date) { friday }

            it "returns Saturday" do
              expect(successor.soonest_start).to eq(saturday)
            end
          end
        end
      end

      context "with the parent having a predecessor" do
        let(:work_packages) { [predecessor, successor, successor_child] }

        context "with a due date" do
          let(:predecessor_due_date) { Date.current }

          it { expect(successor_child.soonest_start).to eq(predecessor.due_date + 1) }

          context "with the parent manually scheduled" do
            let(:successor_schedule_manually) { true }

            it { expect(successor_child.soonest_start).to be_nil }
          end
        end

        context "without dates" do
          it { expect(successor_child.soonest_start).to be_nil }
        end
      end

      context "with the grandparent having a predecessor" do
        let(:work_packages) { [predecessor, successor, successor_child, successor_grandchild] }

        context "with a due date" do
          let(:predecessor_due_date) { Date.current }

          it { expect(successor_grandchild.soonest_start).to eq(predecessor.due_date + 1) }

          context "with the grandparent manually scheduled" do
            let(:successor_schedule_manually) { true }

            it { expect(successor_grandchild.soonest_start).to be_nil }
          end

          context "with the parent manually scheduled" do
            let(:successor_child_schedule_manually) { true }

            it { expect(successor_grandchild.soonest_start).to be_nil }
          end
        end

        context "without dates" do
          it { expect(successor_grandchild.soonest_start).to be_nil }
        end
      end
    end
  end

  describe "#destroy" do
    shared_let(:work_package) { create(:work_package) }
    shared_let(:other_work_package) { create(:work_package) }

    context "for a work package with a relation as to" do
      let!(:to_relation) { create(:follows_relation, from: other_work_package, to: work_package) }

      it "removes the relation as well as the work package" do
        work_package.destroy

        expect(Relation)
          .not_to exist(id: to_relation.id)
      end
    end

    context "for a work package with a relation as from" do
      let!(:from_relation) { create(:follows_relation, to: other_work_package, from: work_package) }

      it "removes the relation as well as the work package" do
        work_package.destroy

        expect(Relation)
          .not_to exist(id: from_relation.id)
      end
    end
  end

  # The combination is speced because it is implemented in a non trivial way.
  describe "#relations.visible" do
    let!(:user) { create(:user) }
    let!(:view_work_packages_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let!(:no_permission_role) { create(:project_role, permissions: %i[]) }
    let!(:sharing_role) { create(:work_package_role, permissions: %i[view_work_packages]) }

    let!(:visible_project) { create(:project, members: { user => view_work_packages_role }) }
    let!(:invisible_project) { create(:project, members: { user => no_permission_role }) }

    let!(:origin) { create(:work_package, project: visible_project) }
    let!(:visible_work_package) { create(:work_package, project: visible_project) }
    let!(:another_visible_work_package) { create(:work_package, project: visible_project) }
    let!(:invisible_work_package) { create(:work_package, project: invisible_project) }
    let!(:other_work_package) { create(:work_package, project: visible_project) }
    let!(:shared_work_package) do
      create(:work_package, project: invisible_project) do |wp|
        create(:work_package_member, entity: wp, user: user, roles: [sharing_role])
      end
    end

    let!(:visible_relation) { create(:relation, from: origin, to: visible_work_package) }
    let!(:inverted_visible_relation) { create(:relation, to: origin, from: another_visible_work_package) }
    let!(:invisible_relation) { create(:relation, from: origin, to: invisible_work_package) }
    let!(:shared_relation) { create(:relation, from: origin, to: shared_work_package) }
    let!(:other_relation) { create(:relation, from: other_work_package, to: visible_work_package) }

    it "returns all relations from the called on work package visible to the user" do
      expect(origin.relations.visible(user))
        .to contain_exactly(visible_relation, inverted_visible_relation, shared_relation)
    end
  end
end
