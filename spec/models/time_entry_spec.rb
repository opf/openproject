require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TimeEntry do

  before(:each) do
    User.current = users("admin")
    @example = time_entries "example"
  end

  fixtures :users
  fixtures :time_entries
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

  it "should return the current costs depending on the number of hours" do
    (0..100).each do |hours|
      @example.hours = hours
      @example.save!
      @example.costs.should == @example.rate.rate * hours
    end
  end

  it "should update cost if a new rate is added at the end" do
    @example.user = User.current
    @example.spent_on = Time.now
    @example.hours = 1
    @example.save!
    @example.costs.should == rates("hourly_one").rate
    hourly = HourlyRate.create! :valid_from => 1.day.ago, :rate => 1.0,
                                :user => User.current, :project => rates("hourly_one").project
    @example.reload
    @example.rate.should_not == rates("hourly_one")
    @example.costs.should == hourly.rate
  end

  it "should update cost if a new rate is added in between" do
    @example.user = User.current
    @example.spent_on = 3.days.ago.to_date
    @example.hours = 1
    @example.save!
    @example.costs.should == rates("hourly_three").rate
    hourly = HourlyRate.create! :valid_from => 3.days.ago.to_date, :rate => 1.0,
                                :user => User.current, :project => rates("hourly_one").project
    @example.reload
    @example.rate.should_not == rates("hourly_three")
    @example.costs.should == hourly.rate
  end

  it "should update cost if a spent_on changes" do
    @example.hours = 1
    (5.days.ago..Time.now).step(1.day) do |time|
      @example.spent_on = time.to_date
      @example.save!
      @example.costs.should == @example.user.rate_at(time, 1).rate
    end
  end

  it "should update cost if a rate is removed" do
    hourly_one = rates("hourly_one")
    @example.spent_on = hourly_one.valid_from
    @example.hours = 1
    @example.save!
    @example.costs.should == hourly_one.rate
    hourly_one.destroy
    @example.reload
    @example.costs.should == rates("hourly_three").rate
    rates("hourly_three").destroy
    @example.reload
    @example.costs.should == rates("hourly_five").rate
  end

end