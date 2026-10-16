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

RSpec.describe Relation do
  create_shared_association_defaults_for_work_package_factory

  let(:from) { create(:work_package) }
  let(:to) { create(:work_package) }
  let(:type) { "relates" }
  let(:relation) { build(:relation, from:, to:, relation_type: type) }

  it "validates lag numericality" do
    expect(relation).to validate_numericality_of(:lag)
      .is_greater_than_or_equal_to(Relation::MIN_LAG)
      .is_less_than_or_equal_to(Relation::MAX_LAG)
      .allow_nil
  end

  it "validates relation uniqueness on both from_id and to_id" do
    create(:relation, from:, to:)

    relation = build(:relation, from:, to:)
    expect(relation).not_to be_valid
    expect(relation.errors.as_json).to include(to: ["has already been taken."])

    other = create(:work_package)
    relation = build(:relation, from:, to: other)
    expect(relation).to be_valid

    relation = build(:relation, from: other, to:)
    expect(relation).to be_valid
  end

  describe "all relation types" do
    Relation::TYPES.each do |key, type_hash|
      let(:type) { key }
      let(:reversed) { type_hash[:reverse] }

      before do
        relation.save!
      end

      it "sets the correct type for for '#{key}'" do
        if reversed.nil?
          expect(relation.relation_type).to eq(type)
        else
          expect(relation.relation_type).to eq(reversed)
        end
      end
    end
  end

  describe "#relation_type= / #relation_type" do
    let(:type) { Relation::TYPE_RELATES }

    it "sets the type" do
      relation.relation_type = Relation::TYPE_BLOCKS
      expect(relation.relation_type).to eq(Relation::TYPE_BLOCKS)
    end
  end

  describe "follows / precedes" do
    context "for FOLLOWS" do
      let(:type) { Relation::TYPE_FOLLOWS }

      it "is not reversed" do
        expect(relation.save).to be(true)
        relation.reload

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end

      it "fails validation with invalid date and reverses" do
        relation.lag = "xx"
        expect(relation).not_to be_valid
        expect(relation.save).to be(false)

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.to).to eq(to)
        expect(relation.from).to eq(from)
      end
    end

    context "for PRECEDES" do
      let(:type) { Relation::TYPE_PRECEDES }

      it "is reversed" do
        expect(relation.save).to be(true)
        relation.reload

        expect(relation.relation_type).to eq(Relation::TYPE_FOLLOWS)
        expect(relation.from).to eq(to)
        expect(relation.to).to eq(from)
      end
    end
  end

  describe "#follows?" do
    context "for a follows relation" do
      let(:type) { Relation::TYPE_FOLLOWS }

      it "is truthy" do
        expect(relation)
          .to be_follows
      end
    end

    context "for a precedes relation" do
      let(:type) { Relation::TYPE_PRECEDES }

      it "is truthy" do
        expect(relation)
          .to be_follows
      end
    end

    context "for a blocks relation" do
      let(:type) { Relation::TYPE_BLOCKS }

      it "is falsey" do
        expect(relation)
          .not_to be_follows
      end
    end
  end

  describe "#successor_soonest_start" do
    context "with a follows relation" do
      let_work_packages(<<~TABLE)
        subject  | MTWTFSS | predecessors
        main     | ]       |
        follower |         | follows main
      TABLE

      it "returns predecessor due_date + 1" do
        relation = _table.relation(successor: "follower")
        expect(relation.successor_soonest_start).to eq(_table.tuesday)
      end
    end

    context "with a follows relation with predecessor having only start date" do
      let_work_packages(<<~TABLE)
        subject  | MTWTFSS | predecessors
        main     | [       |
        follower |         | follows main
      TABLE

      it "returns predecessor start_date + 1" do
        relation = _table.relation(successor: "follower")
        expect(relation.successor_soonest_start).to eq(_table.tuesday)
      end
    end

    context "with a non-follows relation" do
      let_work_packages(<<~TABLE)
        subject | MTWTFSS |
        main    | X       |
        related |         |
      TABLE
      let(:relation) { create(:relation, from: main, to: related) }

      it "returns nil" do
        expect(relation.successor_soonest_start).to be_nil
      end
    end

    context "with a follows relation with a lag" do
      let_work_packages(<<~TABLE)
        subject    | MTWTFSS | predecessors
        main       | X       |
        follower_a |         | follows main with lag 0
        follower_b |         | follows main with lag 1
        follower_c |         | follows main with lag 3
      TABLE

      it "returns predecessor due_date + lag + 1" do
        relation_a = _table.relation(successor: "follower_a")
        expect(relation_a.successor_soonest_start).to eq(_table.tuesday)

        relation_b = _table.relation(successor: "follower_b")
        expect(relation_b.successor_soonest_start).to eq(_table.wednesday)

        relation_c = _table.relation(successor: "follower_c")
        expect(relation_c.successor_soonest_start).to eq(_table.friday)
      end
    end

    context "with a follows relation with a lag and with non-working days in the lag period" do
      let_work_packages(<<~TABLE)
        subject       | MTWTFSSmtw | predecessors
        main          | X░ ░ ░░ ░  |
        follower_lag0 |  ░ ░ ░░ ░  | follows main with lag 0
        follower_lag1 |  ░ ░ ░░ ░  | follows main with lag 1
        follower_lag2 |  ░ ░ ░░ ░  | follows main with lag 2
        follower_lag3 |  ░ ░ ░░ ░  | follows main with lag 3
        follower_lag4 |  ░ ░ ░░ ░  | follows main with lag 4
      TABLE

      it "returns the soonest date for which the number of working days between " \
         "both work packages is equal to the lag" do
        set_work_week("monday", "wednesday", "friday")

        relation_lag0 = _table.relation(successor: "follower_lag0")
        expect(relation_lag0.successor_soonest_start).to eq(_table.tuesday)

        relation_lag1 = _table.relation(successor: "follower_lag1")
        expect(relation_lag1.successor_soonest_start).to eq(_table.thursday) # working day in between is Wednesday

        relation_lag2 = _table.relation(successor: "follower_lag2")
        expect(relation_lag2.successor_soonest_start).to eq(_table.saturday) # working days in between are Wednesday and Friday

        relation_lag3 = _table.relation(successor: "follower_lag3")
        expect(relation_lag3.successor_soonest_start).to eq(_table.next_tuesday) # Wednesday, Friday, next Monday

        relation_lag4 = _table.relation(successor: "follower_lag4")
        expect(relation_lag4.successor_soonest_start).to eq(_table.next_thursday) # Wednesday, Friday, next Monday, next Wednesday
      end
    end

    context "with a follows relation with a lag, non-working days, and followers ignoring non-working days" do
      let_work_packages(<<~TABLE)
        subject       | MTWTFSSmtw | days counting     | predecessors
        main          | X░ ░ ░░ ░  | working days only |
        follower_lag0 |  ░ ░ ░░ ░  | all days          | follows main with lag 0
        follower_lag1 |  ░ ░ ░░ ░  | all days          | follows main with lag 1
        follower_lag2 |  ░ ░ ░░ ░  | all days          | follows main with lag 2
        follower_lag3 |  ░ ░ ░░ ░  | all days          | follows main with lag 3
        follower_lag4 |  ░ ░ ░░ ░  | all days          | follows main with lag 4
      TABLE

      it "returns the soonest date for which the number of working days between " \
         "both work packages is equal to the lag (saying it another way: it is the same " \
         "regardless of followers ignoring non-working days or not)" do
        set_work_week("monday", "wednesday", "friday")

        relation_lag0 = _table.relation(successor: "follower_lag0")
        expect(relation_lag0.successor_soonest_start).to eq(_table.tuesday)

        relation_lag1 = _table.relation(successor: "follower_lag1")
        expect(relation_lag1.successor_soonest_start).to eq(_table.thursday) # working day in between is Wednesday

        relation_lag2 = _table.relation(successor: "follower_lag2")
        expect(relation_lag2.successor_soonest_start).to eq(_table.saturday) # working days in between are Wednesday and Friday

        relation_lag3 = _table.relation(successor: "follower_lag3")
        expect(relation_lag3.successor_soonest_start).to eq(_table.next_tuesday) # Wednesday, Friday, next Monday

        relation_lag4 = _table.relation(successor: "follower_lag4")
        expect(relation_lag4.successor_soonest_start).to eq(_table.next_thursday) # Wednesday, Friday, next Monday, next Wednesday
      end
    end
  end
end
