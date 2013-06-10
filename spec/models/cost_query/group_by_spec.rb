require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, :reporting_query_helper => true do
  let!(:project1){ FactoryGirl.create(:project_with_trackers) }
  let!(:issue1) { FactoryGirl.create(:issue, project: project1) }
  let!(:time_entry1) { FactoryGirl.create(:time_entry, issue: issue1, project: project1, spent_on: Date.new(2012, 1, 1)) }
  let!(:time_entry2) do
    time_entry2 = time_entry1.dup
    time_entry2.save!
    time_entry2
  end
  let!(:cost_object1) { FactoryGirl.create(:cost_object, project: project1) }
  let!(:cost_entry1) { FactoryGirl.create(:cost_entry, issue: issue1, project: project1, spent_on: Date.new(2013, 2, 3)) }
  let!(:cost_entry2) do
    cost_entry2 =  cost_entry1.dup
    cost_entry2.save!
    cost_entry2
  end

  let!(:project2) { FactoryGirl.create(:project_with_trackers) }
  let!(:issue2) { FactoryGirl.create(:issue, project: project2) }
  let!(:time_entry3) { FactoryGirl.create(:time_entry, issue: issue2, project: project2, spent_on: Date.new(2013, 2, 3)) }
  let!(:time_entry4) do
    time_entry4 = time_entry3.dup
    time_entry4.save!
    time_entry4
  end
  let!(:cost_object2) { FactoryGirl.create(:cost_object, project: project2) }
  let!(:cost_entry3) { FactoryGirl.create(:cost_entry, issue: issue2, project: project2, spent_on: Date.new(2012, 1, 1)) }
  let!(:cost_entry4) do
    cost_entry4 =  cost_entry3.dup
    cost_entry4.save!
    cost_entry4
  end

  minimal_query

  describe CostQuery::GroupBy do
    it "should compute group_by on projects" do
      @query.group_by :project_id
      @query.result.size.should == 2
    end

    it "should keep own and all parents' group fields in all_group_fields" do
      @query.group_by :project_id
      @query.group_by :issue_id
      @query.group_by :cost_type_id
      @query.all_group_fields.should == %w[entries.cost_type_id]
      @query.child.all_group_fields.should == %w[entries.cost_type_id entries.issue_id]
      @query.child.child.all_group_fields.should == %w[entries.cost_type_id entries.issue_id entries.project_id]
    end

    it "should compute group_by Issue" do
      @query.group_by :issue_id
      @query.result.size.should == 2
    end

    it "should compute group_by CostType" do
      @query.group_by :cost_type_id
      # type 'Labor' for time entries, 2 different cost types
      @query.result.size.should == 3
    end

    it "should compute group_by Activity" do
      @query.group_by :activity_id
      # "-1" for time entries, 2 different cost activities
      @query.result.size.should == 3
    end

    it "should compute group_by Date (day)" do
      @query.group_by :spent_on
      @query.result.size.should == 2
    end

    it "should compute group_by Date (week)" do
      @query.group_by :tweek
      @query.result.size.should == 2
    end

    it "should compute group_by Date (month)" do
      @query.group_by :tmonth
      @query.result.size.should == 2
    end

    it "should compute group_by Date (year)" do
      @query.group_by :tyear
      @query.result.size.should == 2
    end

    it "should compute group_by User" do
      @query.group_by :user_id
      @query.result.size.should == 4
    end

    it "should compute group_by Tracker" do
      @query.group_by :tracker_id
      @query.result.size.should == 1
    end

    it "should compute group_by CostObject" do
      @query.group_by :cost_object_id
      @query.result.size.should == 1
    end

    it "should compute multiple group_by" do
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result

      sql_result.size.should == 4
      # for each user the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        sub_result.fields.should include(:user_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| sub_sub_result.fields.should include(:project_id) }
      end
      sql_sizes.sort.should == [1, 1, 1, 1]
    end

    # TODO: ?
    it "should compute multiple group_by with joins" do
      @query.group_by :project_id
      @query.group_by :tracker_id
      sql_result = @query.result
      sql_result.size.should == 1
      # for each tracker the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        # tracker should be the outmost group_by
        sub_result.fields.should include(:tracker_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| sub_sub_result.fields.should include(:project_id) }
      end
      sql_sizes.sort.should == [2]
    end

    it "compute count correct with lots of group_by" do
      @query.group_by :project_id
      @query.group_by :issue_id
      @query.group_by :cost_type_id
      @query.group_by :activity_id
      @query.group_by :spent_on
      @query.group_by :tweek
      @query.group_by :tracker_id
      @query.group_by :tmonth
      @query.group_by :tyear

      @query.result.count.should == 8
    end

    it "should accept row as a specialised group_by" do
      @query.row :project_id
      @query.chain.type.should == :row
    end

    it "should accept column as a specialised group_by" do
      @query.column :project_id
      @query.chain.type.should == :column
    end

    it "should have type :column as a default" do
      @query.group_by :project_id
      @query.chain.type.should == :column
    end

    it "should aggregate a third group_by which owns at least 2 sub results" do

      @query.group_by :tweek
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result

      sql_result.size.should == 4
      # for each user the number of projects should be correct
      sql_sizes = []
      sub_sql_sizes = []
      sql_result.each do |sub_result|
        # user should be the outmost group_by
        sub_result.fields.should include(:user_id)
        sql_sizes.push sub_result.size

        sub_result.each do |sub_sub_result|
          sub_sub_result.fields.should include(:project_id)
          sub_sql_sizes.push sub_sub_result.size

          sub_sub_result.each do |sub_sub_sub_result|
            sub_sub_sub_result.fields.should include(:tweek)
          end
        end
      end
      sql_sizes.sort.should == [1, 1, 1, 1]
      sub_sql_sizes.sort.should == [1, 1, 1, 1]
    end

    describe CostQuery::GroupBy::CustomFieldEntries do
      let!(:project){ FactoryGirl.create(:project_with_trackers) }

      before do
        create_issue_custom_field("Searchable Field")
        CostQuery::GroupBy.all.merge CostQuery::GroupBy::CustomFieldEntries.all
      end

      def check_cache
        CostReportsController.new.check_cache
        CostQuery::GroupBy::CustomFieldEntries.all
      end

      def create_issue_custom_field(name)
        IssueCustomField.create(:name => name,
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

      def delete_issue_custom_field(name)
        IssueCustomField.find_by_name(name).destroy
        check_cache
      end

      it "should create classes for custom fields" do
        # Would raise a name error
        CostQuery::GroupBy::CustomFieldSearchableField
      end

      it "should create new classes for custom fields that get added after starting the server" do
        create_issue_custom_field("AFreshCustomField")
        # Would raise a name error
        CostQuery::GroupBy::CustomFieldAfreshcustomfield
        IssueCustomField.find_by_name("AFreshCustomField").destroy
      end

      it "should remove the custom field classes after it is deleted" do
        create_issue_custom_field("AFreshCustomField")
        delete_issue_custom_field("AFreshCustomField")
        CostQuery::GroupBy.all.should_not include CostQuery::GroupBy::CustomFieldAfreshcustomfield
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        CostQuery::GroupBy::CustomFieldEntries.all.
          should include(CostQuery::GroupBy::CustomFieldSearchableField)
      end

      it "includes custom fields classes in GroupBy.all" do
        CostQuery::GroupBy.all.
          should include(CostQuery::GroupBy::CustomFieldSearchableField)
      end

      it "is usable as filter" do
        create_issue_custom_field("Database")
        @query.group_by :custom_field_searchable_field
        footprint = @query.result.each_direct_result.map { |c| [c.count, c.units.to_i] }.sort
        footprint.should == [[8, 8]]
      end
    end
  end
end
