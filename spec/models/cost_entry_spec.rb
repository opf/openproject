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

  it "should update cost if a new rate is added at the end" do
    @example.cost_type = cost_types("umbrella")
    @example.spent_on = Time.now
    @example.units = 1
    @example.save!
    @example.costs.should == rates("cheap_one").rate
    cheap = CostRate.create! :valid_from => 1.day.ago, :rate => 1.0, :cost_type => cost_types("umbrella")
    @example.reload
    @example.rate.should_not == rates("cheap_one")
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

  it "should update cost if a rate is removed" do
    cheap_one = rates("cheap_one")
    @example.spent_on = rates("cheap_one").valid_from
    @example.units = 1
    @example.save!
    @example.costs.should == cheap_one.rate
    cheap_one.destroy
    @example.reload
    @example.costs.should == rates("cheap_three").rate
    rates("cheap_three").destroy
    @example.reload
    @example.costs.should == rates("cheap_five").rate
  end

end