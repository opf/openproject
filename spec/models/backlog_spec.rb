require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Backlog do
  let(:project) { Factory.build(:project) }

  before(:each) do
    @feature = Factory.create(:tracker_feature)
    Setting.plugin_backlogs  = {"points_burn_direction" => "down",
                                "wiki_template"         => "",
                                "card_spec"             => "Sattleford VM-5040",
                                "story_trackers"        => [@feature.id.to_s],
                                "task_tracker"          => "0"}
    @status = Factory.create(:issue_status)
  end

  describe "Class Methods" do
    describe :owner_backlogs do
      describe "WITH one open version defined in the project" do
        before(:each) do
          @project = project
          @issues = [Factory.create(:issue, :subject => "issue1", :project => @project, :tracker => @feature, :status => @status)]
          @version = Factory.create(:version, :project => project, :fixed_issues => @issues)
          @version_settings = VersionSetting.create :display => VersionSetting::DISPLAY_RIGHT, :project => project, :version => @version
        end

        it { Backlog.owner_backlogs(@project)[0].should be_owner_backlog }
      end
    end
  end

end
