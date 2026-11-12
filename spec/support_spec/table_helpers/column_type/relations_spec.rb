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
  RSpec.describe "Relations" do
    subject(:column_type) { described_class.new }

    def parsed_data(table)
      TableHelpers::TableParser.new.parse(table)
    end

    it "can merge relations from multiple relation columns" do
      work_package_data = parsed_data(<<~TABLE).pluck(:relations)
        | predecessors    | relates to |
        | main            |            |
        |                 | related wp |
        | main with lag 3 | related wp |
      TABLE
      expect(work_package_data)
        .to eq([
                 {
                   "main" => { raw: "main", type: :follows, with: "main", lag: 0 }
                 },
                 {
                   "related wp" => { raw: "related wp", type: :relates, with: "related wp" }
                 },
                 {
                   "main" => { raw: "main with lag 3", type: :follows, with: "main", lag: 3 },
                   "related wp" => { raw: "related wp", type: :relates, with: "related wp" }
                 }
               ])
    end
  end
end
