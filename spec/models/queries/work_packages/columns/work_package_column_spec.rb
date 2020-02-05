#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Columns::WorkPackageColumn, type: :model do
  it "allows to be constructed with attribute highlightable" do
    expect(described_class.new('foo', highlightable: true).highlightable?).to eq(true)
  end

  it "allows to be constructed without attribute highlightable" do
    expect(described_class.new('foo').highlightable?).to eq(false)
  end

  describe "sum of" do
    describe :estimated_hours do
      context "with work packages in a hierarchy" do
        let(:work_packages) do
          hierarchy = [
            ["Single", 1, 0],
            {
              ["Parent", 1, 3] => [
                ["Child 1 of Parent", 1, 0],
                ["Child 2 of Parent", 1, 0],
                ["Hidden Child 3 of Parent", 1, 0]
              ]
            },
            {
              ["Hidden Parent", 5, 4] => [
                ["Child of Hidden Parent", 1, 0],
                ["Hidden Child", 3, 0]
              ]
            },
            {
              ["Parent 2", 1, 3] => [
                ["Child 1 of Parent 2", 1, 0],
                {
                  ["Nested Parent", 0, 2] => [
                    ["Child 1 of Nested Parent", 1, 0],
                    ["Child 2 of Nested Parent", 1, 0]
                  ]
                }
              ]
            }
          ]

          build_work_package_hierarchy hierarchy, :subject, :estimated_hours, :derived_estimated_hours
        end

        let(:result_set) { WorkPackage.where("NOT subject LIKE 'Hidden%'") }
        let(:column) { Queries::WorkPackages::Columns::WorkPackageColumn.new :estimated_hours }

        before do
          work_packages # create work packages

          expect(WorkPackage.count).to eq work_packages.size
          expect(result_set.count).to eq(work_packages.size - 3) # all work packages except the hidden parent and children
        end

        it "yields the correct sum, not counting any children (of parents in the result set) twice" do
          # Single + Parent + Child 1 of Parent + Child 2 of Parent + Child of Hidden Parent + Parent 2 + Child 1 of Parent 2
          # + Nested Parent + Child 1 of Nested Parent + Child 2 of Nested Parent
          expect(column.sum_of(result_set)).to eq 9
          expect(column.sum_of(WorkPackage.all)).to eq 18 # the above + Hidden Child 3 of Parent + Hidden Parent + Hidden Child
        end
      end
    end
  end
end
