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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

RSpec.describe CostQuery, :reporting_query_helper do
  before do
    create(:admin)
    project = create(:project_with_types)
    work_package = create(:work_package, project:)
    create(:time_entry, work_package:, project:)
    create(:cost_entry, work_package:, project:)
  end

  minimal_query

  describe CostQuery::Result do
    def direct_results(quantity = 0)
      (1..quantity).map { |i| CostQuery::Result.new real_costs: i.to_f, count: 1, units: i.to_f }
    end

    def wrapped_result(source, quantity = 1)
      CostQuery::Result.new((1..quantity).map { |_i| source })
    end

    it "travels recursively depth-first" do
      # build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]
      previous_depth = -1
      w.recursive_each_with_level do |level, result|
        # depth first, so we should get deeper into the hole, until we find a direct_result
        expect(previous_depth).to eq(level - 1)
        previous_depth = level
        break if result.is_a? CostQuery::Result::DirectResult
      end
    end

    it "travels recursively width-first" do
      # build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      previous_depth = -1
      w.recursive_each_with_level 0, false do |level, _result|
        # width first, so we should get only deeper into the hole without ever coming up again
        expect(previous_depth).to be <= level
        previous_depth = level
      end
    end

    it "travels to all results width-first" do
      # build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      count = 0
      w.recursive_each_with_level 0, false do |_level, result|
        # width first
        count = count + 1 if result.is_a? CostQuery::Result::DirectResult
      end
      expect(w.count).to eq(count)
    end

    it "travels to all results width-first" do
      # build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      count = 0
      w.recursive_each_with_level do |_level, result|
        # depth first
        count = count + 1 if result.is_a? CostQuery::Result::DirectResult
      end
      expect(w.count).to eq(count)
    end

    it "computes count correctly" do
      expect(query.result.count).to eq(Entry.count)
    end

    it "computes units correctly" do
      expect(query.result.units).to eq(Entry.all.sum(&:units))
    end

    it "computes real_costs correctly" do
      expect(query.result.real_costs).to eq(Entry.all.sum { |e| e.overridden_costs || e.costs })
    end

    it "computes count for DirectResults" do
      expect(query.result.values[0].count).to eq(1)
    end

    it "computes units for DirectResults" do
      id_sorted = query.result.values.sort_by { |r| r[:id] }
      te_result = id_sorted.find { |r| r[:type] == TimeEntry.to_s }
      ce_result = id_sorted.find { |r| r[:type] == CostEntry.to_s }
      expect(te_result.units.to_s).to eq("1.0")
      expect(ce_result.units.to_s).to eq("1.0")
    end

    it "computes real_costs for DirectResults" do
      id_sorted = query.result.values.sort_by { |r| r[:id] }
      [CostEntry].each do |type|
        result = id_sorted.find { |r| r[:type] == type.to_s }
        first = type.all.first
        expect(result.real_costs).to eq(first.overridden_costs || first.costs)
      end
    end

    it "is a column if created with CostQuery.column" do
      query.column :project_id
      expect(query.result.type).to eq(:column)
    end

    it "is a row if created with CostQuery.row" do
      query.row :project_id
      expect(query.result.type).to eq(:row)
    end

    it "shows the type :direct for its direct results" do
      query.column :project_id
      expect(query.result.first.first.type).to eq(:direct)
    end
  end
end
