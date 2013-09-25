require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Backlog do
  let(:project) { FactoryGirl.build(:project) }

  before(:each) do
    @feature = FactoryGirl.create(:type_feature)
    Setting.plugin_openproject_backlogs  = {"points_burn_direction" => "down",
                                "wiki_template"         => "",
                                "card_spec"             => "Sattleford VM-5040",
                                "story_types"        => [@feature.id.to_s],
                                "task_type"          => "0"}
    @status = FactoryGirl.create(:issue_status)
  end

  describe "Class Methods" do
    describe :owner_backlogs do
      describe "WITH one open version defined in the project" do
        before(:each) do
          @project = project
          @work_packages = [FactoryGirl.create(:work_package, :subject => "work_package1", :project => @project, :type => @feature, :status => @status)]
          @version = FactoryGirl.create(:version, :project => project, :fixed_issues => @work_packages)
          @version_settings = @version.version_settings.create(:display => VersionSetting::DISPLAY_RIGHT, :project => project)
        end

        it { Backlog.owner_backlogs(@project)[0].should be_owner_backlog }
      end
    end
  end

end
