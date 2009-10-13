require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do
  
  before do
    User.current = users("admin")
  end

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues

  it "should always prefer overridden_costs" do
    example = cost_entries "example"
    value = rand(500)
    example.overridden_costs = value
    example.overridden_costs.should == value
    example.real_costs.should == value
    example.save!
  end

end