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
  RSpec.describe TableRepresenter do
    let(:table) do
      <<~TABLE
        | subject      | remaining work | derived remaining work |
        | Work Package |           1.5h |                     9h |
      TABLE
    end
    let(:table_data) { TableData.for(table) }
    let(:tables_data) { [table_data] }

    subject(:representer) { described_class.new(tables_data:, columns:) }

    context "when using a second table for the size" do
      let(:twin_table) do
        <<~TABLE
          | subject                        |
          | A quite long work package name |
        TABLE
      end
      let(:twin_table_data) { TableData.for(twin_table) }

      let(:tables_data) { [table_data, twin_table_data] }
      let(:columns) { [Column.for("subject")] }

      it "adapts the column sizes to fit the largest value of both tables " \
         "so that they can be compared and diffed" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | subject                        |
          | Work Package                   |
        TABLE
        expect(representer.render(twin_table_data)).to eq <<~TABLE
          | subject                        |
          | A quite long work package name |
        TABLE
      end
    end

    context "when there are no work packages" do
      let(:table_data) do
        TableData.from_work_packages([], columns)
      end
      let(:columns) { [Column.for("subject")] }

      it "renders no rows" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | subject |
        TABLE
      end
    end

    describe "subject column" do
      let(:columns) { [Column.for("subject")] }

      it "is rendered as text" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | subject      |
          | Work Package |
        TABLE
      end
    end

    describe "remaining work column" do
      let(:columns) { [Column.for("remaining work")] }

      it "is rendered as a duration" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | remaining work |
          |           1.5h |
        TABLE
      end
    end

    describe "derived remaining work column" do
      let(:columns) { [Column.for("derived remaining work")] }

      it "sets the derived remaining work attribute" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | derived remaining work |
          |                     9h |
        TABLE
      end
    end

    describe "schedule column" do
      let(:table) do
        <<~TABLE
          | subject |   MTWTFSS   |
          | wp1     |   X         |
          | wp2     |     [       |
          | wp3     |       ]     |
          | wp4     |             |
          | wp5     |    XXX      |
          | wp6     | X           |
          | wp7     |           X |
          | wp8     |           X |
        TABLE
      end
      let(:columns) { [Column.for("MTWTFSS")] }

      it "is rendered as a schedule" do
        expect(representer.render(table_data)).to eq <<~TABLE
          |   MTWTFSS   |
          |   X         |
          |     [       |
          |       ]     |
          |             |
          |    XXX      |
          | X           |
          |           X |
          |           X |
        TABLE
      end

      context "when there are no work packages" do
        let(:table_data) do
          TableData.from_work_packages([], columns)
        end

        it "renders no rows" do
          expect(representer.render(table_data)).to eq <<~TABLE
            | MTWTFSS |
          TABLE
        end
      end

      context "when non working days are defined" do
        let(:table) do
          <<~TABLE
            | subject | MTWTFSS | days counting
            | wp1     | XXXXXXX | working days only
            | wp2     | XXXXXXX | all days
          TABLE
        end

        before do
          set_non_working_week_days("wednesday", "thursday")
        end

        it "renders the non working days as dots `.` for work packages taking non-working days into account" do
          expect(representer.render(table_data)).to eq <<~TABLE
            | MTWTFSS |
            | XX..XXX |
            | XXXXXXX |
          TABLE
        end

        context "when using a second table which does not have the ignore_non_working_days attribute knowledge" do
          let(:twin_table) do
            <<~TABLE
              | subject | MTWTFSS |
              | wp1     | XXXXXXX |
              | wp2     | XXXXXXX |
            TABLE
          end
          let(:twin_table_data) { TableData.for(twin_table) }
          let(:tables_data) { [table_data, twin_table_data] }

          it "renders the non working days as dots `.` for both tables" do
            expect(representer.render(table_data)).to eq <<~TABLE
              | MTWTFSS |
              | XX..XXX |
              | XXXXXXX |
            TABLE
            expect(representer.render(twin_table_data)).to eq <<~TABLE
              | MTWTFSS |
              | XX..XXX |
              | XXXXXXX |
            TABLE
          end
        end
      end

      context "when using a second table for the size" do
        let(:twin_table) do
          <<~TABLE
            | subject | MTWTFSS          |
            | wp5     |  XXX             |
            | wp9     |               XX |
          TABLE
        end
        let(:twin_table_data) { TableData.for(twin_table) }

        let(:tables_data) { [table_data, twin_table_data] }

        it "adapts the column size to the largest of both tables so they are diffable" do
          expect(representer.render(table_data)).to eq <<~TABLE
            |   MTWTFSS          |
            |   X                |
            |     [              |
            |       ]            |
            |                    |
            |    XXX             |
            | X                  |
            |           X        |
            |           X        |
          TABLE
          expect(representer.render(twin_table_data)).to eq <<~TABLE
            |   MTWTFSS          |
            |    XXX             |
            |                 XX |
          TABLE
        end
      end
    end

    describe "hierarchy column" do
      let(:table) do
        <<~TABLE
          | hierarchy        |
          | wp1              |
          | parent           |
          |   child1         |
          |     grandchild11 |
          |     grandchild12 |
          |   child2         |
          |   child3         |
          |     grandchild31 |
          |     grandchild32 |
          | wp3              |
        TABLE
      end
      let(:columns) { [Column.for("hierarchy")] }

      it "is rendered as a hierarchy" do
        expect(representer.render(table_data)).to eq <<~TABLE
          | hierarchy        |
          | wp1              |
          | parent           |
          |   child1         |
          |     grandchild11 |
          |     grandchild12 |
          |   child2         |
          |   child3         |
          |     grandchild31 |
          |     grandchild32 |
          | wp3              |
        TABLE
      end

      context "when there are no work packages" do
        let(:table_data) do
          TableData.from_work_packages([], columns)
        end

        it "renders no rows" do
          expect(representer.render(table_data)).to eq <<~TABLE
            | hierarchy |
          TABLE
        end
      end

      context "when using a second table for the column size" do
        let(:twin_table) do
          <<~TABLE
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
        end
        let(:twin_table_data) { TableData.for(twin_table) }

        let(:tables_data) { [table_data, twin_table_data] }

        it "adapts the column size to the largest of both tables so they are diffable" do # rubocop:disable RSpec/ExampleLength
          expect(representer.render(table_data)).to eq <<~TABLE
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
          expect(representer.render(twin_table_data)).to eq <<~TABLE
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
        end
      end
    end
  end
end
