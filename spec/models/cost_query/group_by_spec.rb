#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, :type => :model, :reporting_query_helper => true do
  let!(:type) { FactoryGirl.create(:type) }
  let!(:project1){ FactoryGirl.create(:project_with_types, types: [type]) }
  let!(:work_package1) { FactoryGirl.create(:work_package, project: project1, type: type)}
  let!(:time_entry1) { FactoryGirl.create(:time_entry, work_package: work_package1, project: project1, spent_on: Date.new(2012, 1, 1)) }
  let!(:time_entry2) do
    time_entry2 = time_entry1.dup
    time_entry2.save!
    time_entry2
  end
  let!(:cost_object1) { FactoryGirl.create(:cost_object, project: project1) }
  let!(:cost_entry1) { FactoryGirl.create(:cost_entry, work_package: work_package1, project: project1, spent_on: Date.new(2013, 2, 3)) }
  let!(:cost_entry2) do
    cost_entry2 =  cost_entry1.dup
    cost_entry2.save!
    cost_entry2
  end

  let!(:project2) { FactoryGirl.create(:project_with_types, types: [type]) }
  let!(:work_package2) { FactoryGirl.create(:work_package, project: project2, type: type) }
  let!(:time_entry3) { FactoryGirl.create(:time_entry, work_package: work_package2, project: project2, spent_on: Date.new(2013, 2, 3)) }
  let!(:time_entry4) do
    time_entry4 = time_entry3.dup
    time_entry4.save!
    time_entry4
  end
  let!(:cost_object2) { FactoryGirl.create(:cost_object, project: project2) }
  let!(:cost_entry3) { FactoryGirl.create(:cost_entry, work_package: work_package2, project: project2, spent_on: Date.new(2012, 1, 1)) }
  let!(:cost_entry4) do
    cost_entry4 =  cost_entry3.dup
    cost_entry4.save!
    cost_entry4
  end

  minimal_query

  describe CostQuery::GroupBy do
    it "should compute group_by on projects" do
      @query.group_by :project_id
      expect(@query.result.size).to eq(2)
    end

    it "should keep own and all parents' group fields in all_group_fields" do
      @query.group_by :project_id
      @query.group_by :work_package_id
      @query.group_by :cost_type_id
      expect(@query.all_group_fields).to eq(%w[entries.cost_type_id])
      expect(@query.child.all_group_fields).to eq(%w[entries.cost_type_id entries.work_package_id])
      expect(@query.child.child.all_group_fields).to eq(%w[entries.cost_type_id entries.work_package_id entries.project_id])
    end

    it "should compute group_by WorkPackage" do
      @query.group_by :work_package_id
      expect(@query.result.size).to eq(2)
    end

    it "should compute group_by CostType" do
      @query.group_by :cost_type_id
      # type 'Labor' for time entries, 2 different cost types
      expect(@query.result.size).to eq(3)
    end

    it "should compute group_by Activity" do
      @query.group_by :activity_id
      # "-1" for time entries, 2 different cost activities
      expect(@query.result.size).to eq(3)
    end

    it "should compute group_by Date (day)" do
      @query.group_by :spent_on
      expect(@query.result.size).to eq(2)
    end

    it "should compute group_by Date (week)" do
      @query.group_by :tweek
      expect(@query.result.size).to eq(2)
    end

    it "should compute group_by Date (month)" do
      @query.group_by :tmonth
      expect(@query.result.size).to eq(2)
    end

    it "should compute group_by Date (year)" do
      @query.group_by :tyear
      expect(@query.result.size).to eq(2)
    end

    it "should compute group_by User" do
      @query.group_by :user_id
      expect(@query.result.size).to eq(4)
    end

    it "should compute group_by Type" do
      @query.group_by :type_id
      expect(@query.result.size).to eq(1)
    end

    it "should compute group_by CostObject" do
      @query.group_by :cost_object_id
      expect(@query.result.size).to eq(1)
    end

    it "should compute multiple group_by" do
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result

      expect(sql_result.size).to eq(4)
      # for each user the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        expect(sub_result.fields).to include(:user_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| expect(sub_sub_result.fields).to include(:project_id) }
      end
      expect(sql_sizes.sort).to eq([1, 1, 1, 1])
    end

    # TODO: ?
    it "should compute multiple group_by with joins" do
      @query.group_by :project_id
      @query.group_by :type_id
      sql_result = @query.result
      expect(sql_result.size).to eq(1)
      # for each type the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # type should be the outmost group_by
        expect(sub_result.fields).to include(:type_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| expect(sub_sub_result.fields).to include(:project_id) }
      end
      expect(sql_sizes.sort).to eq([2])
    end

    it "compute count correct with lots of group_by" do
      @query.group_by :project_id
      @query.group_by :work_package_id
      @query.group_by :cost_type_id
      @query.group_by :activity_id
      @query.group_by :spent_on
      @query.group_by :tweek
      @query.group_by :type_id
      @query.group_by :tmonth
      @query.group_by :tyear

      expect(@query.result.count).to eq(8)
    end

    it "should accept row as a specialised group_by" do
      @query.row :project_id
      expect(@query.chain.type).to eq(:row)
    end

    it "should accept column as a specialised group_by" do
      @query.column :project_id
      expect(@query.chain.type).to eq(:column)
    end

    it "should have type :column as a default" do
      @query.group_by :project_id
      expect(@query.chain.type).to eq(:column)
    end

    it "should aggregate a third group_by which owns at least 2 sub results" do

      @query.group_by :tweek
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result

      expect(sql_result.size).to eq(4)
      # for each user the number of projects should be correct
      sql_sizes = []
      sub_sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        expect(sub_result.fields).to include(:user_id)
        sql_sizes.push sub_result.size

        sub_result.each do |sub_sub_result|
          expect(sub_sub_result.fields).to include(:project_id)
          sub_sql_sizes.push sub_sub_result.size

          sub_sub_result.each do |sub_sub_sub_result|
            expect(sub_sub_sub_result.fields).to include(:tweek)
          end
        end
      end
      expect(sql_sizes.sort).to eq([1, 1, 1, 1])
      expect(sub_sql_sizes.sort).to eq([1, 1, 1, 1])
    end

    describe CostQuery::GroupBy::CustomFieldEntries do
      let!(:project){ FactoryGirl.create(:project_with_types) }

      before do
        create_work_package_custom_field("Searchable Field")
        CostQuery::GroupBy.all.merge CostQuery::GroupBy::CustomFieldEntries.all
      end

      def check_cache
        CostReportsController.new.check_cache
        CostQuery::GroupBy::CustomFieldEntries.all
      end

      def create_work_package_custom_field(name)
        WorkPackageCustomField.create(:name => name,
                                      :min_length => 1,
                                      :regexp => "",
                                      :is_for_all => true,
                                      :max_length => 100,
                                      :possible_values => "",
                                      :is_required => false,
                                      :field_format => "string",
                                      :searchable => true,
                                      :default_value => "Default string",
                                      :editable => true)
        check_cache
      end

      def delete_work_package_custom_field(name)
        WorkPackageCustomField.find_by_name(name).destroy
        check_cache
      end

      def class_name_for(name)
        "CostQuery::GroupBy::CustomField#{WorkPackageCustomField.find_by_name(name).id}"
      end

      it "should create classes for custom fields" do
        # Would raise a name error
        expect { class_name_for('Searchable Field').constantize }.to_not raise_error
      end

      it "should create new classes for custom fields that get added after starting the server" do
        create_work_package_custom_field("AFreshCustomField")
        # Would raise a name error
        expect { class_name_for('AFreshCustomField').constantize }.to_not raise_error
        WorkPackageCustomField.find_by_name("AFreshCustomField").destroy
      end

      it "should remove the custom field classes after it is deleted" do
        create_work_package_custom_field("AFreshCustomField")
        name = class_name_for('AFreshCustomField')
        delete_work_package_custom_field("AFreshCustomField")
        expect(CostQuery::GroupBy.all).not_to include name.constantize
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        expect(CostQuery::GroupBy::CustomFieldEntries.all).
          to include(class_name_for('Searchable Field').constantize)
      end

      it "includes custom fields classes in GroupBy.all" do
        expect(CostQuery::GroupBy.all).
          to include(class_name_for('Searchable Field').constantize)
      end

      it "is usable as filter" do
        create_work_package_custom_field("Database")
        id = WorkPackageCustomField.find_by_name('Database').id
        @query.group_by "custom_field_#{id}".to_sym
        footprint = @query.result.each_direct_result.map { |c| [c.count, c.units.to_i] }.sort
        expect(footprint).to eq([[8, 8]])
      end
    end
  end
end
