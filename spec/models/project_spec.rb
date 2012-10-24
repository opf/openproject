require 'spec_helper'

describe Project do
  describe Project::STATUS_ACTIVE do
    it "equals 1" do
      # spec that STATUS_ACTIVE has the correct value
      Project::STATUS_ACTIVE.should == 1
    end
  end
  
  describe "#active?" do
    before do
      # stub out the actual value of the constant
      stub_const('Project::STATUS_ACTIVE', 42)
    end
    
    it "is active when :status equals STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 42
      project.should be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 99
      project.should_not be_active
    end
  end
end
