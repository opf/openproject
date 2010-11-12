require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do

  before(:each) do
    User.current = users("admin")
    @example = issues "some_issue"
  end

  fixtures :users
  fixtures :time_entries
  fixtures :rates
  fixtures :projects
  fixtures :projects_trackers
  fixtures :issues
  fixtures :trackers
  fixtures :enumerations
  fixtures :issue_statuses
  fixtures :cost_objects

  it "should update cost entries on move" do
    @example.project_id.should eql 1
    
    @example.move_to(projects(:projects_002)).should_not be_false
    CostEntry.find(1).project_id.should eql 2
  end
  
  it "should allow to set cost_object to nil" do
    @example.cost_object_id = 1
    @example.save!    
    @example.cost_object_id.should eql 1
    
    @example.cost_object_id = nil
    lambda { @example.save! }.should_not raise_error(ActiveRecord::RecordInvalid)
  end
end