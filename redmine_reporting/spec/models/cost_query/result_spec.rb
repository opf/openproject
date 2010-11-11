require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  before { User.current = users(:admin) }
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

  describe CostQuery::Result do
    def direct_results(quantity = 0)
      (1..quantity).collect {|i| CostQuery::Result.new :real_costs=>i.to_f, :count=>1 ,:units=>i.to_f}
    end

    def wrapped_result(source, quantity=1)
      CostQuery::Result.new((1..quantity).collect { |i| source})
    end

    it "should travel recursively depth-first" do
      #build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]
      previous_depth = -1
      w.recursive_each_with_level do |level, result|
        #depth first, so we should get deeper into the hole, until we find a direct_result
        previous_depth.should == level - 1
        previous_depth=level
        break if result.is_a? CostQuery::Result::DirectResult
      end
    end

    it "should travel recursively width-first" do
      #build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      previous_depth = -1
      w.recursive_each_with_level 0, false do |level, result|
        #width first, so we should get only deeper into the hole without ever coming up again
        previous_depth.should <= level
        previous_depth=level
      end
    end

    it "should travel to all results width-first" do
      #build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      count = 0
      w.recursive_each_with_level 0, false do |level, result|
        #width first
        count = count + 1 if result.is_a? CostQuery::Result::DirectResult
      end
      w.count.should ==  count
    end

    it "should travel to all results width-first" do
      #build a tree of wrapped and direct results
      w1 = wrapped_result((direct_results 5), 3)
      w2 = wrapped_result wrapped_result((direct_results 3), 2)
      w = wrapped_result [w1, w2]

      count = 0
      w.recursive_each_with_level do |level, result|
        #depth first
          count = count + 1 if result.is_a? CostQuery::Result::DirectResult
        end
      w.count.should ==  count
    end

    it "should compute count correctly" do
      @query.result.count.should == Entry.count
    end

    it "should compute units correctly" do
      @query.result.units.should == Entry.all.map { |e| e.units}.sum
    end

    it "should compute real_costs correctly" do
      @query.result.real_costs.should == Entry.all.map { |e| e.overridden_costs || e.costs}.sum
    end

    it "should compute count for DirectResults" do
      @query.result.values[0].count.should == 1
    end

    it "should compute units for DirectResults" do
      id_sorted = @query.result.values.sort_by { |r| r[:id] }
      te_result = id_sorted.select { |r| r[:type]==TimeEntry.to_s }.first
      ce_result = id_sorted.select { |r| r[:type]==CostEntry.to_s }.first
      te_result.units.should == TimeEntry.all.first.hours
      ce_result.units.should == CostEntry.all.first.units
    end

    it "should compute real_costs for DirectResults" do
      id_sorted = @query.result.values.sort_by { |r| r[:id] }
      [CostEntry].each do |type|
        result = id_sorted.select { |r| r[:type]==type.to_s }.first
        first = type.all.first
        result.real_costs.should == (first.overridden_costs || first.costs)
      end
    end

    it "should be a column if created with CostQuery.column" do
      @query.column :project_id
      @query.result.type.should == :column
    end

    it "should be a row if created with CostQuery.row" do
      @query.row :project_id
      @query.result.type.should == :row
    end

    it "should show the type :direct for its direct results" do
      @query.column :project_id
      @query.result.first.first.type.should == :direct
    end

  end
end
