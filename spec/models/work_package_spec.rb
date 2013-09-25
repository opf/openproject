require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  describe :backlogs_types do
    it "should return all the ids of types that are configures to be considered backlogs types" do
      Setting.stub(:plugin_openproject_backlogs).and_return({"story_types" => [1], "task_type" => 2})

      WorkPackage.backlogs_types.should =~ [1,2]
    end

    it "should return an empty array if nothing is defined" do
      Setting.stub(:plugin_openproject_backlogs).and_return({})

      WorkPackage.backlogs_types.should == []
    end

    it 'should reflect changes to the configuration' do
      Setting.stub(:plugin_openproject_backlogs).and_return({"story_types" => [1], "task_type" => 2})
      WorkPackage.backlogs_types.should =~ [1,2]

      Setting.stub(:plugin_openproject_backlogs).and_return({"story_types" => [3], "task_type" => 4})
      WorkPackage.backlogs_types.should =~ [3,4]
    end
  end
end
