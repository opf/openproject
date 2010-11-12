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

  describe "the reporting system" do
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

    it "should process only _one_ SQL query for any operations on a valid CostQuery" do
      #hook the point where we generate the SQL query
      class CostQuery::SqlStatement
        alias_method :original_to_s, :to_s

        def self.on_generate(&block)
          @@on_generate = block || proc{}
        end

        def to_s
          @@on_generate.call self if @@on_generate
          original_to_s
        end
      end
      # create a random query
      @query.group_by :issue_id
      @query.column :tweek
      @query.row :project_id
      @query.row :user_id
      #count how often a sql query was created
      number_of_sql_queries = 0
      CostQuery::SqlStatement.on_generate do |sql_statement|
        number_of_sql_queries += 1 unless caller.third.include? 'sql_statement.rb'
      end
      # do some random things on it
      walker = @query.transformer
      walker.row_first
      walker.column_first
      # TODO - to do something
      CostQuery::SqlStatement.on_generate # do nothing
      number_of_sql_queries.should == 1
    end
  end
end