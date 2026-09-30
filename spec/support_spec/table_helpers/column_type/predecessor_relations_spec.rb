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

module TableHelpers::ColumnType
  RSpec.describe PredecessorRelations do
    subject(:column_type) { described_class.new }

    def parsed_data(table)
      TableHelpers::TableParser.new.parse(table)
    end

    describe "empty" do
      it "stores nothing when empty" do
        work_package_data = parsed_data(<<~TABLE).first
          | predecessors |
          |              |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty

        work_package_data = parsed_data(<<~TABLE).first
          | predecessors
          |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty
      end
    end

    describe "[follows] <predecessor> [with lag <nb_days>]" do
      it "stores follows relations in work_package_data" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | predecessors            |
          | follows main with lag 3 |
          | main with lag 3         |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "main" => { raw: "follows main with lag 3", type: :follows, with: "main", lag: 3 }
                   },
                   {
                     "main" => { raw: "main with lag 3", type: :follows, with: "main", lag: 3 }
                   }
                 ])
      end

      it "has a default lag of 0 days when not specified" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | predecessors |
          | follows main |
          | main         |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "main" => { raw: "follows main", type: :follows, with: "main", lag: 0 }
                   },
                   {
                     "main" => { raw: "main", type: :follows, with: "main", lag: 0 }
                   }
                 ])
      end

      it "can store multiple relations" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | predecessors             |
          | follows wp1, follows wp2 |
          | follows wp1, wp2, wp3    |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "wp1" => { raw: "follows wp1", type: :follows, with: "wp1", lag: 0 },
                     "wp2" => { raw: "follows wp2", type: :follows, with: "wp2", lag: 0 }
                   },
                   {
                     "wp1" => { raw: "follows wp1", type: :follows, with: "wp1", lag: 0 },
                     "wp2" => { raw: "wp2", type: :follows, with: "wp2", lag: 0 },
                     "wp3" => { raw: "wp3", type: :follows, with: "wp3", lag: 0 }
                   }
                 ])
      end
    end
  end
end
