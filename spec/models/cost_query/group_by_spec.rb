require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  before { @query = CostQuery.new }

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

  describe CostQuery::GroupBy do
    it "should compute group_by on projects" do
      @query.group_by :project_id
      @query.result.size.should == Entry.all.group_by { |e| e.project }.size
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
  end
end