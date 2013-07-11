require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  describe :backlogs_trackers do
    it "should return all the ids of trackers that are configures to be considered backlogs trackers" do
      Setting.plugin_openproject_backlogs = { "story_trackers"        => [1],
                                              "task_tracker"          => 2 }

      WorkPackage.backlogs_trackers.should =~ [1,2]
    end

    it "should return an empty array if nothing is defined" do
      Setting.plugin_openproject_backlogs = { }

      WorkPackage.backlogs_trackers.should == []
    end

    it 'should reflect changes to the configuration' do
      Setting.plugin_openproject_backlogs = { "story_trackers"        => [1],
                                              "task_tracker"          => 2 }

      WorkPackage.backlogs_trackers.should =~ [1,2]

      Setting.plugin_openproject_backlogs = { "story_trackers"        => [3],
                                              "task_tracker"          => 4 }

      Setting.plugin_openproject_backlogs["story_trackers"] = [3]
      Setting.plugin_openproject_backlogs["task_tracker"] = [4]

      WorkPackage.backlogs_trackers.should =~ [3,4]
    end
  end
end
