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

  describe "Integration tests" do
    it "should compute group_by and a filter" do
      @query.group_by :project_id
      @query.filter :status_id, :operator => 'o'
      sql_result = @query.result
      ruby_result = Entry.all.select { |e| ! e.issue.status.is_closed? }.group_by { |e| e.project_id }

      sql_result.size.should == ruby_result.size
      #for each project the number of entries should be correct
      sql_count = []
      sql_result.each do |sub_result|
        #project should be the outmost group_by
        sub_result.fields.should include(:project_id)
        sql_count.push sub_result.count
      end
      ruby_count = []
      ruby_result.each do |sub_result_array|
        ruby_count.push sub_result_array.second.size
      end
      sql_count.sort.should == ruby_count.sort
    end

    it "should apply two filter and a group_by correctly" do
      @query.filter :project_id, :operator => '=', :value => [1, 2, 3, 4, 5]
      @query.group_by :user_id
      @query.filter :overridden_costs, :operator => 'n'

      sql_result = @query.result
      ruby_result = Entry.all.select { |e| e.project_id > 0 && e.project_id < 6 && e.overridden_costs == nil }.group_by { |e| e.user_id }
      sql_result.size.should == ruby_result.size
      #for each user the number of entries should be correct
      sql_count = []
      sql_result.each do |sub_result|
        #project should be the outmost group_by
        sub_result.fields.should include(:user_id)
        sql_count.push sub_result.count
      end
      ruby_count = []
      ruby_result.each do |sub_result_array|
        ruby_count.push sub_result_array.second.size
      end
      sql_count.sort.should == ruby_count.sort
    end

    it "should apply two different filter on the same field" do
      @query.filter :project_id, :operator => '=', :value => [1, 2, 3, 4, 5]
      @query.filter :project_id, :operator => '!', :value => [2, 5]

      sql_result = @query.result
      ruby_result = Entry.all.select { |e| e.project_id == 1 || e.project_id == 3 || e.project_id == 4 }
      sql_result.count.should == ruby_result.size
    end
  end
end