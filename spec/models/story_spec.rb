require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Story do
  let(:user) { @user ||= Factory.create(:user) }
  let(:role) { @role ||= Factory.create(:role) }
  let(:issue_status1) { @status1 ||= Factory.create(:issue_status, :name => "status 1", :is_default => true) }
  let(:tracker_feature) { @tracker_feature ||= Factory.create(:tracker_feature) }
  let(:version) { @version ||= Factory.create(:version, :project => project) }
  let(:sprint) { @sprint ||= Factory.create(:sprint, :project => project) }
  let(:issue_priority) { @issue_priority ||= Factory.create(:priority) }

  let(:project) do
    unless @project
      @project = Factory.build(:project)
      @project.members = [Factory.build(:member, :principal => user,
                                                 :project => @project,
                                                 :roles => [role])]
    end
    @project
  end

  before(:each) do
    Setting.use_caching = false

    Setting.plugin_backlogs = {:points_burn_direction => "down",
                               :wiki_template => "",
                               :card_spec => "Sattleford VM-5040",
                               :story_trackers => [tracker_feature.id.to_s],
                               :task_tracker => "0"}
  end

  describe "Class methods" do
    describe :condition do

      it {Story.condition(1, 2).should eql(["project_id = ? AND tracker_id in (?) AND fixed_version_id = ?", 1, [tracker_feature.id], 2])}
    end

    describe :backlog do
      describe "WITH the user having the right to view issues" do
        before(:each) do
          role.permissions << :view_issues
          role.save!
        end

        describe "WITH the sprint having 1 story" do
          before(:each) do
            @story1 = Factory.create(:story, :fixed_version => version,
                                             :project => project,
                                             :status => issue_status1,
                                             :tracker => tracker_feature)
          end

          it { Story.backlog(project, version).should eql [@story1] }
        end

        describe "WITH the sprint having one story in this project and one story in another project" do
          before(:each) do
            version.sharing = "system"
            version.save!

            @another_project = Factory.create(:project)

            @story1 = Factory.create(:story, :fixed_version => version,
                                             :project => project,
                                             :status => issue_status1,
                                             :tracker => tracker_feature,
                                             :priority => issue_priority)

            @story2 = Factory.create(:story, :fixed_version => version,
                                             :project => @another_project,
                                             :status => issue_status1,
                                             :tracker => tracker_feature,
                                             :priority => issue_priority)
            true
          end

          it { Story.backlog(project, version).should have(1).items }
          it { Story.backlog(project, version)[0].should eql @story1 }
        end
      end
    end
  end
end
