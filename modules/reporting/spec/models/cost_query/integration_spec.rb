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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, type: :model, reporting_query_helper: true do
  minimal_query

  let!(:project1){ FactoryBot.create(:project_with_types) }
  let!(:work_package1) { FactoryBot.create(:work_package, project: project1) }
  let!(:time_entry1) { FactoryBot.create(:time_entry, work_package: work_package1, project: project1) }
  let!(:time_entry2) { FactoryBot.create(:time_entry, work_package: work_package1, project: project1) }

  let!(:project2) { FactoryBot.create(:project_with_types) }
  let!(:work_package2) { FactoryBot.create(:work_package, project: project2) }
  let!(:time_entry3) { FactoryBot.create(:time_entry, work_package: work_package2, project: project2) }
  let!(:time_entry4) { FactoryBot.create(:time_entry, work_package: work_package2, project: project2) }

  before do
    FactoryBot.create(:admin)
  end

  describe "the reporting system" do
    it "should compute group_by and a filter" do
      @query.group_by :project_id
      @query.filter :status_id, operator: 'o'
      sql_result = @query.result

      expect(sql_result.size).to eq(2)
      #for each project the number of entries should be correct
      sql_count = []
      sql_result.each do |sub_result|
        #project should be the outmost group_by
        expect(sub_result.fields).to include(:project_id)
        sql_count.push sub_result.count
      end
      expect(sql_count.sort).to eq([2, 2])
    end

    it "should apply two filter and a group_by correctly" do
      @query.filter :project_id, operator: '=', value: [project1.id]
      @query.group_by :user_id
      @query.filter :overridden_costs, operator: 'n'

      sql_result = @query.result
      expect(sql_result.size).to eq(2)
      #for each user the number of entries should be correct
      sql_count = []
      sql_result.each do |sub_result|
        #project should be the outmost group_by
        expect(sub_result.fields).to include(:user_id)
        sql_count.push sub_result.count
      end
      expect(sql_count.sort).to eq([1, 1])
    end

    it "should apply two different filters on the same field" do
      @query.filter :project_id, operator: '=', value: [project1.id, project2.id]
      @query.filter :project_id, operator: '!', value: [project2.id]

      sql_result = @query.result
      expect(sql_result.count).to eq(2)
    end

    it 'should process only _one_ SQL query for any operations on a valid CostQuery' do
      number_of_sql_queries = 0
      expect_any_instance_of(CostQuery::SqlStatement).to receive(:to_s) do |*_|
        number_of_sql_queries += 1 unless caller.third.include? 'sql_statement.rb'

        # Apparently, we have to return a valid SQL query

        'SELECT 1=1'
      end

      # create a random query
      @query.group_by :work_package_id
      @query.column :tweek
      @query.row :project_id
      @query.row :user_id
      # count how often a sql query was created
      number_of_sql_queries = 0
      # do some random things on it
      walker = @query.transformer
      walker.row_first
      walker.column_first
      # TODO - to do something
    end
  end
end
