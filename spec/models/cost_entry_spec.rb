require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do

  before(:each) do
    User.current = users("admin")
    @example = cost_entries "example"
  end

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :enumerations
  fixtures :issue_statuses

  it "should always prefer overridden_costs" do
    value = rand(500)
    @example.overridden_costs = value
    @example.overridden_costs.should == value
    @example.real_costs.should == value
    @example.save!
  end

  it "should return the current costs depending on the number of units" do
    (0..100).each do |units|
      @example.units = units
      @example.save!
      @example.costs.should == @example.cost_type.rate_at(@example.spent_on).rate * units
    end
  end

  it "should update cost if a new rate is added" do
    @example.cost_type = cost_types("umbrella")
    @example.spent_on = Time.now
    @example.units = 1
    @example.save!
    @example.costs.should == rates("cheap_one").rate
    cheap = CostRate.create! :valid_from => 12.hours.ago, :rate => 1.0, :cost_type => cost_types("umbrella")
    @example.costs.should == cheap.rate
  end

  it "should update cost if a spent_on changes" do
    @example.units = 1
    (5.days.ago..Time.now).step(1.day) do |time|
      @example.spent_on = time
      @example.save!
      @example.costs.should == @example.cost_type.rate_at(time).rate
    end
  end

end