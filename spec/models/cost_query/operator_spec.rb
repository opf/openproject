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

  describe CostQuery::Operator do
    def query(table, field, operator, *values)
      sql = CostQuery::SqlStatement.new table
      yield sql if block_given?
      operator.to_operator.modify sql, field, *values
      ActiveRecord::Base.connection.select_all sql.to_s
    end

    def query_on_entries(field, operator, *values)
      sql = CostQuery::SqlStatement.for_entries
      operator.to_operator.modify sql, field, *values
      result = ActiveRecord::Base.connection.select_all sql.to_s
    end

    def create_project(options = {})
      parent = options.delete :parent
      p = Project.mock! options
      p.set_parent! parent if parent
      p
    end

    it "does =" do
      query('projects', 'id', '=', 1).size.should == 1
    end

    it "does = for multiple values" do
      query('projects', 'id', '=', 1, 2).size.should == 2
    end

    it "does = for no values" do
      sql = CostQuery::SqlStatement.new 'projects'
      "=".to_operator.modify sql, 'id'
      result = (ActiveRecord::Base.connection.select_all sql.to_s)
      result.count.should == 0
    end

    it "does = for nil" do
      query('projects', 'id', '=', nil).size.should == 0
    end

    it "does <=" do
      query('projects', 'id', '<=', Project.count - 1).size.should == Project.count - 1
    end

    it "does >=" do
      query('projects', 'id', '>=', Project.first.id + 1).size.should == Project.count - 1
    end

    it "does !" do
      query('projects', 'id', '!', 1).size.should == Project.count - 1
    end

    it "does ! for multiple values" do
      query('projects', 'id', '!', 1, 2).size.should == Project.count - 2
    end

    it "does !*" do
      query('cost_entries', 'project_id', '!*', []).size.should == 0
    end

    it "does !~ (not contains)" do
      query('projects', 'name', '!~', 'o').size.should == Project.all.select { |p| p.name !~ /o/ }.count
    end

    it "does c (closed issue)" do
      query('issues', 'status_id', 'c') { |s| s.join IssueStatus => [Issue, :status] }.size.should >= 0
    end

    it "does o (open issue)" do
      query('issues', 'status_id', 'o') { |s| s.join IssueStatus => [Issue, :status] }.size.should >= 0
    end

    it "does give the correct number of results when counting closed and open issues" do
      a = query('issues', 'status_id', 'o') { |s| s.join IssueStatus => [Issue, :status] }.size
      b = query('issues', 'status_id', 'c') { |s| s.join IssueStatus => [Issue, :status] }.size
      Issue.count.should == a + b
    end

    it "does w (this week)" do
      #somehow this test doesn't work on sundays
      n = query('projects', 'created_on', 'w').size
      day_in_this_week = Time.now.at_beginning_of_week + 1.day
      Project.mock! :created_on => day_in_this_week
      query('projects', 'created_on', 'w').size.should == n + 1
      Project.mock! :created_on => day_in_this_week + 7.days
      Project.mock! :created_on => day_in_this_week - 7.days
      query('projects', 'created_on', 'w').size.should == n + 1
    end

    it "does t (today)" do
      s = query('projects', 'created_on', 't').size
      Project.mock! :created_on => Date.yesterday
      query('projects', 'created_on', 't').size.should == s
      Project.mock! :created_on => Time.now
      query('projects', 'created_on', 't').size.should == s + 1
    end

    it "does <t+ (before the day which is n days in the future)" do
      n = query('projects', 'created_on', '<t+', 2).size
      Project.mock! :created_on => Date.tomorrow + 1
      query('projects', 'created_on', '<t+', 2).size.should == n + 1
      Project.mock! :created_on => Date.tomorrow + 2
      query('projects', 'created_on', '<t+', 2).size.should == n + 1
    end

    it "does t+ (n days in the future)" do
      n = query('projects', 'created_on', 't+', 1).size
      Project.mock! :created_on => Date.tomorrow
      query('projects', 'created_on', 't+', 1).size.should == n + 1
      Project.mock! :created_on => Date.tomorrow + 2
      query('projects', 'created_on', 't+', 1).size.should == n + 1
    end

    it "does >t+ (after the day which is n days in the furure)" do
      n = query('projects', 'created_on', '>t+', 1).size
      Project.mock! :created_on => Time.now
      query('projects', 'created_on', '>t+', 1).size.should == n
      Project.mock! :created_on => Date.tomorrow + 1
      query('projects', 'created_on', '>t+', 1).size.should == n + 1
    end

    it "does >t- (after the day which is n days ago)" do
      n = query('projects', 'created_on', '>t-', 1).size
      Project.mock! :created_on => Date.today
      query('projects', 'created_on', '>t-', 1).size.should == n + 1
      Project.mock! :created_on => Date.yesterday - 1
      query('projects', 'created_on', '>t-', 1).size.should == n + 1
    end

    it "does t- (n days ago)" do
      n = query('projects', 'created_on', 't-', 1).size
      Project.mock! :created_on => Date.yesterday
      query('projects', 'created_on', 't-', 1).size.should == n + 1
      Project.mock! :created_on => Date.yesterday - 2
      query('projects', 'created_on', 't-', 1).size.should == n + 1
    end

    it "does <t- (before the day which is n days ago)" do
      n = query('projects', 'created_on', '<t-', 1).size
      Project.mock! :created_on => Date.today
      query('projects', 'created_on', '<t-', 1).size.should == n
      Project.mock! :created_on => Date.yesterday - 1
      query('projects', 'created_on', '<t-', 1).size.should == n + 1
    end

    #Our own operators
    it "does =_child_projects" do
      n = query('projects', 'id', '=_child_projects', 1).size
      p = Project.find(1)
      n.should == 1 + p.descendants.size
      p_c1 = create_project :parent => p
      query('projects', 'id', '=_child_projects', 1).size.should == n + 1
      create_project :parent => p_c1
      query('projects', 'id', '=_child_projects', 1).size.should == n + 2
    end

    it "does =_child_projects on multiple projects" do
      p1 = create_project
      p2 = create_project
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == 2
      p1_c1 = create_project :parent => p1
      p2_c1 = create_project :parent => p2
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == 4
      p1_c1_c1 = create_project :parent => p1_c1
      create_project :parent => p1_c1_c1
      create_project :parent => p2_c1
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == 7
    end

    it "does !_child_projects" do
      p = create_project
      n = query('projects', 'id', '!_child_projects', p.id).size
      n.should == Project.all.size - 1
      p_c1 = create_project :parent => p
      query('projects', 'id', '!_child_projects', p.id).size.should == n
      create_project :parent => p
      create_project :parent => p_c1
      query('projects', 'id', '!_child_projects', p.id).size.should == n
      create_project
      query('projects', 'id', '!_child_projects', p.id).size.should == n + 1
    end

    it "does !_child_projects on multiple projects" do
      n = Project.all.size
      p1 = create_project
      p2 = create_project
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == n
      p1_c1 = create_project :parent => p1
      p2_c1 = create_project :parent => p2
      create_project
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == n + 1
      p1_c1_c1 = create_project :parent => p1_c1
      create_project :parent => p1_c1_c1
      create_project :parent => p2_c1
      create_project
      query('projects', 'id', '=_child_projects', [p1.id, p2.id]).size.should == n + 2
    end

    it "does =n" do
      # we have a time_entry with costs==4.2 and a cost_entry with costs==2.3 in our fixtures
      query_on_entries('costs', '=n', 4.2).size.should == Entry.all.select { |e| e.costs == 4.2 }.count
      query_on_entries('costs', '=n', 2.3).size.should == Entry.all.select { |e| e.costs == 2.3 }.count
    end

    it "does 0" do
      query_on_entries('costs', '0').size.should == Entry.all.select { |e| e.costs == 0 }.count
    end

    # y/n seem are for filtering overridden costs
    it "does y" do
      query_on_entries('overridden_costs', 'y').size.should == Entry.all.select { |e| e.overridden_costs != nil }.count
    end

    it "does n" do
      query_on_entries('overridden_costs', 'n').size.should == Entry.all.select { |e| e.overridden_costs == nil }.count
    end

    it "does =d" do
      #assuming that there aren't more than one project created at the same time (which actually is not true, but works for the first project in our fixtures)
      query('projects', 'created_on', '=d', Project.first.created_on).size.should == 1
    end

    it "does <d" do
      query('projects', 'created_on', '<d', Time.now).size.should == Project.count
    end

    it "does <>d" do
      query('projects', 'created_on', '<>d', Time.now, 5.minutes.from_now).size.should == 0
    end

    it "does >d" do
      #assuming that all projects were created in the past
      query('projects', 'created_on', '>d', Time.now).size.should == 0
    end

    describe 'arity' do
      arities = {'t' => 0, 'w' => 0, '<>d' => 2, '>d' => 1}
      arities.each do |o,a|
        it("#{o} should take #{a} values") { o.to_operator.arity.should == a }
      end
    end

  end
end
