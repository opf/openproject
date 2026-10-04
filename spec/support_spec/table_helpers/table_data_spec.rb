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

module TableHelpers
  RSpec.describe TableData do
    describe ".for" do
      it "reads a table representation and stores its data" do
        table = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(2)
        expect(table_data.headers).to eq([" subject      ", " remaining work "])
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])
      end
    end

    describe ".from_work_packages" do
      it "reads data from work packages according to the given columns" do
        table = <<~TABLE
          | subject      | status | remaining work |
          | work package | To do  |             3h |
          | another one  | Done   |                |
        TABLE
        columns = described_class.for(table).columns

        status_todo = build(:status, name: "To do")
        status_done = build(:status, name: "Done")
        work_package = build(:work_package, subject: "work package", status: status_todo, remaining_hours: 3)
        another_one = build(:work_package, subject: "another one", status: status_done)

        table_data = described_class.from_work_packages([work_package, another_one], columns)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(3)
        expect(table_data.headers).to eq(["subject", "status", "remaining work"])
        expect(table_data.values_for_attribute(:subject)).to eq(["work package", "another one"])
        expect(table_data.values_for_attribute(:status)).to eq(["To do", "Done"])
        expect(table_data.values_for_attribute(:remaining_hours)).to eq([3.0, nil])
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])
      end

      it "can read schedule column data from work packages" do
        expected_table = <<~TABLE
          | subject        |   MTWTFSS |
          | work package 1 | XXX       |
          | work package 2 |       ]   |
        TABLE

        columns = described_class.for(expected_table).columns
        monday = Date.current.next_occurring(:monday)
        work_package1 = build(:work_package, subject: "work package 1",
                                             start_date: monday - 2, due_date: monday)
        work_package2 = build(:work_package, subject: "work package 2",
                                             start_date: nil, due_date: monday + 4)

        table_data = described_class.from_work_packages([work_package1, work_package2], columns)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(2)
        expect(table_data.headers).to eq(["subject", "MTWTFSS"])
        expect(table_data.values_for_attribute(:start_date))
          .to eq([monday - 2, nil])
        expect(table_data.values_for_attribute(:due_date))
          .to eq([monday, monday + 4])
        expect(table_data.work_package_identifiers).to eq(%i[work_package1 work_package2])
      end
    end

    describe "#headers" do
      it "returns headers of a table data as they were read" do
        table = <<~TABLE
          | subject      | remaining work | derived work |
          | work package |             3h |           3h |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.headers).to eq([" subject      ", " remaining work ", " derived work "])
        expect(table_data.columns.size).to eq(3)
      end

      it "returns headers even if some values are blank in the first row" do
        table = <<~TABLE
          | subject      | remaining work | derived work |
          | work package |                |              |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.headers).to eq([" subject      ", " remaining work ", " derived work "])
        expect(table_data.columns.size).to eq(3)
      end
    end

    describe "#values_for_attribute" do
      it "returns all the values of the work packages for the given attribute" do
        table = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.values_for_attribute(:remaining_hours)).to eq([3.0, nil])
        expect(table_data.values_for_attribute(:subject)).to eq(["work package", "another one"])
      end
    end

    describe "#create_work_packages" do
      let(:monday) { Date.current.next_occurring(:monday) }

      it "creates work packages out of the table data" do
        status = create(:status, name: "To do")
        table_representation = <<~TABLE
          subject | status | work | MTWTFSS |
          My wp   | To do  |   5h | XXX     |
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(1)
        expect(table.work_package(:my_wp))
          .to have_attributes(
            subject: "My wp",
            status:,
            estimated_hours: 5.0,
            start_date: monday,
            due_date: monday + 2.days
          )
      end

      it "creates 'follows' relations between work packages out of the table data" do
        table_representation = <<~TABLE
          subject  | predecessors
          main     |
          follower | follows main with lag 2
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(2)
        main = table.work_package(:main)
        follower = table.work_package(:follower)
        expect(follower.follows_relations.count).to eq(1)
        expect(follower.follows_relations.first.to).to eq(main)
        expect(follower.follows_relations.first.lag).to eq(2)
      end

      it "creates 'precedes' relations between work packages out of the table data" do
        table_representation = <<~TABLE
          subject     | successors
          predecessor | precedes main with lag 2
          main        | precedes successor
          successor   |
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(3)
        predecessor = table.work_package(:predecessor)
        main = table.work_package(:main)
        successor = table.work_package(:successor)

        expect(main.follows_relations.count).to eq(1)
        expect(main.follows_relations.first.predecessor).to eq(predecessor)
        expect(main.follows_relations.first.successor).to eq(main)
        expect(main.follows_relations.first.lag).to eq(2)

        expect(main.precedes_relations.count).to eq(1)
        expect(main.precedes_relations.first.predecessor).to eq(main)
        expect(main.precedes_relations.first.successor).to eq(successor)
        expect(main.precedes_relations.first.lag).to eq(0)
      end

      it "creates 'relates' relations between work packages out of the table data" do
        table_representation = <<~TABLE
          subject  | related to
          main     |
          other    | main
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(2)
        main = table.work_package(:main)
        other = table.work_package(:other)
        expect(other.relations.relates.count).to eq(1)
        expect(other.relations.relates.first.to).to eq(main)
        expect(other.relations.relates.first.lag).to be_nil
      end

      it "can creates 'follows' and 'relates' relations at the same time out of the table data" do
        table_representation = <<~TABLE
          subject     | related to | predecessors
          pred        |            |
          other       |            |
          main        | other      | pred
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(3)
        pred = table.work_package(:pred)
        other = table.work_package(:other)
        main = table.work_package(:main)
        expect(main.relations.count).to eq(2)
        expect(main.relations.relates.first.to).to eq(other)
        expect(main.relations.follows.first.to).to eq(pred)
      end

      it "raises an error if a given status name does not exist" do
        table_representation = <<~TABLE
          subject | status |
          My wp   | To do  |
        TABLE

        expect { described_class.for(table_representation).create_work_packages }
          .to raise_error(NameError, 'No status with name "To do" found. Available statuses are: [].')

        create(:status, name: "Doing")
        create(:status, name: "Done")
        expect { described_class.for(table_representation).create_work_packages }
          .to raise_error(NameError, 'No status with name "To do" found. Available statuses are: ["Doing", "Done"].')

        create(:status, name: "To do")
        expect { described_class.for(table_representation).create_work_packages }
          .not_to raise_error
      end
    end

    describe "#hierarchy_levels" do
      it "returns 0 for each identifier when there is not hierarchy defined" do
        table_representation = <<~TABLE
          | subject |
          | wp1     |
          | wp2     |
        TABLE
        table_data = described_class.for(table_representation)
        expect(table_data.hierarchy_levels).to eq({ wp1: 0, wp2: 0 })
      end

      it "when using hierarchy column, returns 0 for root level work packages, and 1 more for each hierarchy level" do
        table_representation = <<~TABLE
          | hierarchy |
          | parent    |
          |   child   |
        TABLE
        table_data = described_class.for(table_representation)
        expect(table_data.hierarchy_levels).to eq({ parent: 0, child: 1 })

        table_representation = <<~TABLE
          | hierarchy        |
          | parent           |
          |   child1         |
          |     grandchild11 |
          |   child2         |
        TABLE
        table_data = described_class.for(table_representation)
        expect(table_data.hierarchy_levels).to eq({ parent: 0, child1: 1, grandchild11: 2, child2: 1 })
      end
    end

    describe "#order_like" do
      it "orders the table data like the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject      | remaining work |
          | another one  |                |
          | work package |             3h |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package])
      end

      it "ignores unknown rows from the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject      | remaining work |
          | another one  |                |
          | work package |             3h |
          | unknown one  |                |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package])
      end

      it "appends to the bottom the rows missing in the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | extra one    |                |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject           | remaining work |
          | another one       |                |
          | work package      |             3h |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package extra_one another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package extra_one])
      end

      it "deals well with hierarchies when present" do
        table_representation = <<~TABLE
          | hierarchy |
          | parent    |
          |   child   |
          | other     |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | hierarchy       |
          | parent          |
          |   child renamed |
          | other           |
        TABLE
        other_table_data = described_class.for(other_table_representation)

        expect(table_data.work_package_identifiers)
          .to eq(%i[parent child other])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers)
          .to eq(%i[parent child other])
      end

      it "deals well with big hierarchies when present" do # rubocop:disable RSpec/ExampleLength
        table_representation = <<~TABLE
          | hierarchy                |
          | wp1                      |
          | wp3                      |
          | parent                   |
          |   child2                 |
          |     grandchild21         |
          |   child1                 |
          |     grandchild13         |
          |     grandchild12         |
          |       grandgrandchild121 |
          |   child3                 |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | hierarchy                |
          | wp1                      |
          | parent                   |
          |   child1                 |
          |     grandchild11         |
          |     grandchild12         |
          |   child2                 |
          |   child3                 |
          |     grandchild31         |
          |     grandchild32         |
          | wp3                      |
        TABLE
        other_table_data = described_class.for(other_table_representation)

        expect(table_data.work_package_identifiers)
          .to eq(%i[wp1
                    wp3
                    parent
                    child2 grandchild21
                    child1 grandchild13 grandchild12 grandgrandchild121
                    child3])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers)
          .to eq(%i[wp1
                    parent
                    child1 grandchild12 grandgrandchild121 grandchild13
                    child2 grandchild21
                    child3
                    wp3])
      end
    end
  end
end
