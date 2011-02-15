require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  minimal_query

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :time_entries
  fixtures :enumerations
  fixtures :issue_statuses
  fixtures :roles
  fixtures :issue_categories
  fixtures :versions
  fixtures :custom_fields
  fixtures :custom_values

  describe CostQuery::GroupBy do
    it "should compute group_by on projects" do
      @query.group_by :project_id
      @query.result.size.should == Entry.all.group_by { |e| e.project }.size
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
      @query.result.size.should == Entry.all.group_by { |e| e.issue }.size
    end

    it "should compute group_by CostType" do
      @query.group_by :cost_type_id
      @query.result.size.should == Entry.all.group_by { |e| e.cost_type }.size
    end

    it "should compute group_by Activity" do
      @query.group_by :activity_id
      @query.result.size.should == Entry.all.group_by { |e| e.activity_id }.size
    end

    it "should compute group_by Date (day)" do
      @query.group_by :spent_on
      @query.result.size.should == Entry.all.group_by { |e| e.spent_on }.size
    end

    it "should compute group_by Date (week)" do
      @query.group_by :tweek
      @query.result.size.should == Entry.all.group_by { |e| e.tweek }.size
    end

    it "should compute group_by Date (month)" do
      @query.group_by :tmonth
      @query.result.size.should == Entry.all.group_by { |e| e.tmonth }.size
    end

    it "should compute group_by Date (year)" do
      @query.group_by :tyear
      @query.result.size.should == Entry.all.group_by { |e| e.tyear }.size
    end

    it "should compute group_by User" do
      @query.group_by :user_id
      @query.result.size.should == Entry.all.group_by { |e| e.user }.size
    end

    it "should compute group_by Tracker" do
      @query.group_by :tracker_id
      @query.result.size.should == Entry.all.group_by { |e| e.issue.tracker }.size
    end

    it "should compute group_by CostObject" do
      @query.group_by :cost_object_id
      @query.result.size.should == Entry.all.group_by { |e| e.issue.cost_object }.size
    end

    it "should compute multiple group_by" do
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result
      ruby_result = Entry.all.group_by { |e| e.user_id }

      sql_result.size.should == ruby_result.size
      #for each user the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        #user should be the outmost group_by
        sub_result.fields.should include(:user_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| sub_sub_result.fields.should include(:project_id) }
      end
      ruby_sizes = []
      ruby_result.each do |sub_result_array|
        sub_group = sub_result_array.second.group_by { |e| e.project_id }
        ruby_sizes.push sub_group.size
      end
      sql_sizes.sort.should == ruby_sizes.sort
    end

    it "should compute multiple group_by with joins" do
      @query.group_by :project_id
      @query.group_by :tracker_id
      sql_result = @query.result
      ruby_result = Entry.all.group_by { |e| e.issue.tracker_id }

      sql_result.size.should == ruby_result.size
      #for each tracker the number of projects should be correct
      sql_sizes = []
      sql_result.each do |sub_result|
        #tracker should be the outmost group_by
        sub_result.fields.should include(:tracker_id)
        sql_sizes.push sub_result.size
        sub_result.each { |sub_sub_result| sub_sub_result.fields.should include(:project_id) }
      end
      ruby_sizes = []
      ruby_result.each do |sub_result_array|
        sub_group = sub_result_array.second.group_by { |e| e.project_id }
        ruby_sizes.push sub_group.size
      end
      sql_sizes.sort.should == ruby_sizes.sort
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

      sql_result = @query.result
      sql_result.count.should == Entry.all.size
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
      #validate preconditions
      Entry.all.map { |e| e.user_id }.uniq.size.should > 1 #we should test with more than one subresult for the first wrapped result

      @query.group_by :tweek
      @query.group_by :project_id
      @query.group_by :user_id
      sql_result = @query.result
      ruby_result = Entry.all.group_by { |e| e.user_id }

      sql_result.size.should == ruby_result.size
      #for each user the number of projects should be correct
      sql_sizes = []
      sub_sql_sizes = []
      sql_result.each do |sub_result|
        #user should be the outmost group_by
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
      ruby_sizes = []
      sub_ruby_sizes = []
      ruby_result.each do |sub_result_array|
        sub_group = sub_result_array.second.group_by { |e| e.project_id }
        ruby_sizes.push sub_group.size
        sub_group.each do |sub_sub_result_array|
          sub_sub_group = sub_sub_result_array.second.group_by { |e| e.tweek }
          sub_ruby_sizes.push sub_sub_group.size
        end
      end

      sql_sizes.sort.should == ruby_sizes.sort
      sub_sql_sizes.sort.should == sub_ruby_sizes.sort
    end

    describe CostQuery::GroupBy::CustomFieldEntries do
      before do
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
        lambda { CostQuery::GroupBy::CustomFieldAfreshcustomfield }.
          should raise_error(NameError)
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
        @query.group_by :custom_field_searchable_field
        footprint = @query.result.each_direct_result.map { |c| [c.count, c.units.to_i] }.sort
        footprint.should == [[1, 1], [2, 2], [2, 3], [8, 11]] # see fixtures
      end
    end
  end
end
