require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  describe :backlogs_types do
    it "should return all the ids of types that are configures to be considered backlogs types" do
      Setting.plugin_openproject_backlogs = { "story_types"        => [1],
                                              "task_type"          => 2 }

      WorkPackage.backlogs_types.should =~ [1,2]
    end

    it "should return an empty array if nothing is defined" do
      Setting.plugin_openproject_backlogs = { }

      WorkPackage.backlogs_types.should == []
    end

    it 'should reflect changes to the configuration' do
      Setting.plugin_openproject_backlogs = { "story_types"        => [1],
                                              "task_type"          => 2 }

      WorkPackage.backlogs_types.should =~ [1,2]

      Setting.plugin_openproject_backlogs = { "story_types"        => [3],
                                              "task_type"          => 4 }

      Setting.plugin_openproject_backlogs["story_types"] = [3]
      Setting.plugin_openproject_backlogs["task_type"] = [4]

      WorkPackage.backlogs_types.should =~ [3,4]
    end
  end
end
