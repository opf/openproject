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

RSpec.describe "Scheduling mode switching", # rubocop:disable RSpec/DescribeClass
               with_settings: { journal_aggregation_time_minutes: 0 } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:admin) }

  context "when creating a non-follows relation" do
    context "with 2 manually scheduled work packages" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode |
        | pred          | XX      | manual          |
        | succ          |      XX | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "relates",
          "from_id" => succ.id,
          "to_id" => pred.id
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "keeps work package scheduling mode" do
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |      XX | manual          |
        TABLE
        expect(pred.journals.count).to eq(1)
        expect(succ.journals.count).to eq(1)
      end
    end
  end

  context "when creating a follows relation" do
    context "with 2 manually scheduled work packages" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode |
        | pred          | XX      | manual          |
        | succ          |      XX | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "follows",
          "from_id" => succ.id,
          "to_id" => pred.id
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "switches successor scheduling mode to automatic and reschedules it accordingly" do
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |   XX    | automatic       |
        TABLE
        expect(pred.journals.count).to eq(1)
        expect(succ.journals.count).to eq(2)
      end
    end

    context "with 2 manually scheduled work packages already having the correct dates" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode |
        | pred          | XX      | manual          |
        | succ          |   XX    | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "follows",
          "from_id" => succ.id,
          "to_id" => pred.id
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "switches successor scheduling mode to automatic without rescheduling it" do
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |   XX    | automatic       |
        TABLE
        expect(pred.journals.count).to eq(1)
        expect(succ.journals.count).to eq(2)
      end
    end

    context "with a precedes relation with 2 manually scheduled work packages" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode |
        | pred          | XX      | manual          |
        | succ          |      XX | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "precedes",
          "from_id" => pred.id,
          "to_id" => succ.id
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "switches successor scheduling mode to automatic and reschedules it accordingly" do
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |   XX    | automatic       |
        TABLE
        expect(pred.journals.count).to eq(1)
        expect(succ.journals.count).to eq(2)
      end
    end

    context "with work package being manually scheduled and having an already existing predecessor" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | predecessors
        | work package  |      XX | manual          | existing pred
        | existing pred | XX      | manual          |
        | another pred  | XX      | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "follows",
          "from_id" => work_package.id, # successor
          "to_id" => another_pred.id # predecessor
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "keeps work package scheduling mode (manual) and does not reschedule" do
        expect_work_packages_after_reload([work_package, existing_pred, another_pred], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | work package  |      XX | manual          |
          | existing pred | XX      | manual          |
          | another pred  | XX      | manual          |
        TABLE
        expect(work_package.journals.count).to eq(1)
      end
    end

    context "with work package being manually scheduled and having already at least one child" do
      let_work_packages(<<~TABLE)
        | hierarchy        | MTWTFSS | scheduling mode |
        | work package     |      XX | manual          |
        |   existing child |      XX | manual          |
        | pred             | XX      | manual          |
      TABLE

      before do
        attributes = {
          "relation_type" => "follows",
          "from_id" => work_package.id, # successor
          "to_id" => pred.id # predecessor
        }
        Relations::CreateService.new(user:).call(attributes)
      end

      it "keeps work package scheduling mode (manual) and does not reschedule" do
        expect_work_packages_after_reload([work_package, existing_child, pred], <<~TABLE)
          | subject          | MTWTFSS | scheduling mode |
          | work package     |      XX | manual          |
          |   existing child |      XX | manual          |
          | pred             | XX      | manual          |
        TABLE
        expect(work_package.journals.count).to eq(1)
      end
    end
  end

  ## TODO: Add tests for changing the relation type (currently supported by API only)
  context "when updating an existing follows relation" do
    context "with 2 manually scheduled work packages" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | predecessors
        | pred          | XX      | manual          |
        | succ          |      XX | manual          | pred
      TABLE

      before do
        relation = Relation.last
        update_attributes = {
          "description" => "my description"
        }
        Relations::UpdateService.new(user:, model: relation).call(update_attributes)
      end

      it "keeps work package scheduling mode" do
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |      XX | manual          |
        TABLE
        expect(Relation.last.description).to eq("my description")
        expect(pred.journals.count).to eq(1)
        expect(succ.journals.count).to eq(1)
      end
    end
  end

  context "when deleting a non-follows relation" do
    context "with an automatically scheduled successor for which it's the last relation" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | related to
        | wp1           | XX      | manual          |
        | wp2           |   XX    | automatic       | wp1
      TABLE

      before do
        relation = Relation.last
        Relations::DeleteService.new(user:, model: relation).call
      end

      it "does not switch work package scheduling mode" do
        expect(Relation.count).to eq(0)
        expect_work_packages_after_reload([wp1, wp2], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | wp1           | XX      | manual          |
          | wp2           |   XX    | automatic       |
        TABLE
        expect(wp2.journals.count).to eq(1)
      end
    end
  end

  # TODO: Add the case where two relations exist, one is deleted and the successor needs rescheduling
  context "when deleting a follows relation" do
    context "with an automatically scheduled successor for which it's the last relation" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | predecessors
        | pred          | XX      | manual          |
        | succ          |   XX    | automatic       | pred
      TABLE

      before do
        relation = Relation.last
        Relations::DeleteService.new(user:, model: relation).call
      end

      it "switches work package to manual scheduling mode and keeps the dates" do
        expect(Relation.count).to eq(0)
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |   XX    | manual          |
        TABLE
        expect(succ.journals.count).to eq(2)
      end
    end

    context "with an automatically scheduled successor without any dates for which it's the last relation" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | predecessors
        | pred          |         | manual          |
        | succ          |         | automatic       | pred
      TABLE

      before do
        relation = _table.relation(predecessor: "pred", successor: "succ")
        Relations::DeleteService.new(user:, model: relation).call
      end

      it "switches work package to manual scheduling mode" do
        expect(Relation.count).to eq(0)
        expect_work_packages_after_reload([pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          |         | manual          |
          | succ          |         | manual          |
        TABLE
        expect(succ.journals.count).to eq(2)
      end
    end

    context "with an automatically scheduled successor for which it's not the last relation" do
      let_work_packages(<<~TABLE)
        | subject       | MTWTFSS | scheduling mode | predecessors
        | pred          | XX      | manual          |
        | another pred  | XX      | manual          |
        | succ          |   XX    | automatic       | pred, another pred
      TABLE

      before do
        relation = _table.relation(predecessor: "pred", successor: "succ")
        Relations::DeleteService.new(user:, model: relation).call
      end

      it "keeps work package scheduling mode" do
        expect(Relation.count).to eq(1)
        expect_work_packages_after_reload([pred, another_pred, succ], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | another pred  | XX      | manual          |
          | succ          |   XX    | automatic       |
        TABLE
        expect(succ.journals.count).to eq(1) # no modifications
      end
    end

    context "with an automatically scheduled successor which has at least one child" do
      let_work_packages(<<~TABLE)
        | hierarchy     | MTWTFSS | scheduling mode | predecessors
        | pred          | XX      | manual          |
        | succ          |    XX   | automatic       | pred
        |   child       |    XX   | manual          |
      TABLE

      before do
        relation = Relation.last
        Relations::DeleteService.new(user:, model: relation).call
      end

      it "keeps work package automatic scheduling mode because it has a child" do
        expect(Relation.count).to eq(0)
        expect_work_packages_after_reload([pred, succ, child], <<~TABLE)
          | subject       | MTWTFSS | scheduling mode |
          | pred          | XX      | manual          |
          | succ          |    XX   | automatic       |
          |   child       |    XX   | manual          |
        TABLE
        expect(succ.journals.count).to eq(1) # no changes
      end
    end
  end
end
