require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Backlog do
  let(:project) { Factory.build(:project) }

  before(:each) do
    @feature = Factory.create(:tracker_feature)
    @status = Factory.create(:issue_status)
  end

  describe "Class Methods" do
    describe :owner_backlogs do
      describe "WITH one open version defined in the project" do
        before(:each) do
          @project = project
          @issues = [Factory.create(:issue, :subject => "issue1", :project => @project, :tracker => @feature, :status => @status)]
          @version = Factory.create(:version, :project => project, :fixed_issues => @issues)
          @version_settings = VersionSetting.create :display => VersionSetting::DISPLAY_RIGHT, :version => @version
        end

        it { Backlog.owner_backlogs(@project)[0].should be_owner_backlog }
      end
    end
  end

end