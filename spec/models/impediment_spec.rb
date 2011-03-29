require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Impediment do
  let(:user) { @user ||= Factory.create(:user) }
  let(:role) { @role ||= Factory.create(:role, :permissions => [:edit_issues]) }
  let(:tracker_feature) { @tracker_feature ||= Factory.create(:tracker_feature) }
  let(:tracker_task) { @tracker_task ||= Factory.create(:tracker_task) }
  let(:issue_priority) { @issue_priority ||= Factory.create(:priority, :is_default => true) }
  let(:task) { Factory.build(:task, :tracker => tracker_task,
                                     :project => project,
                                     :author => user,
                                     :priority => issue_priority,
                                     :status => issue_status1) }
  let(:feature) { Factory.build(:issue, :tracker => tracker_feature,
                                        :project => project,
                                        :author => user,
                                        :priority => issue_priority,
                                        :status => issue_status1) }
  let(:version) { @version ||= Factory.create(:version, :project => project) }

  let(:project) do
    unless @project
      @project = Factory.build(:project)
      @project.members = [Factory.build(:member, :principal => user,
                                                 :project => @project,
                                                 :roles => [role])]
    end
    @project
  end

  let(:issue_status1) { @status1 ||= Factory.create(:issue_status, :name => "status 1", :is_default => true) }
  let(:issue_status2) { @status2 ||= Factory.create(:issue_status, :name => "status 2") }
  let(:tracker_workflow) { @workflow ||= Workflow.create(:tracker_id => tracker_task.id,
                                                 :old_status => issue_status1,
                                                 :new_status => issue_status2,
                                                 :role => role) }

  before(:each) do
    Setting.plugin_redmine_backlogs  = {:points_burn_direction => "down",
                                        :wiki_template => "",
                                        :card_spec => "Sattleford VM-5040",
                                        :story_trackers => [tracker_feature.id.to_s],
                                        :task_tracker => tracker_task.id.to_s }

    User.current = user
    project.save
    tracker_workflow.save
  end

  describe "class methods" do
    describe :create_with_relationships do
      describe "WITH a blocking relationship to a story" do
        before(:each) do
          feature.save
          @impediment_subject = "Impediment A"
          @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                              :assigned_to_id => user.id,
                                                              :blocks => feature.id.to_s,
                                                              :status_id => issue_status1.id,
                                                              :fixed_version_id => version.id},
                                                              user.id,
                                                              project.id)

        end

        it { @impediment.should_not be_new_record }
        it { @impediment.subject.should eql @impediment_subject }
        it { @impediment.author.should eql user }
        it { @impediment.project.should eql project }
        it { @impediment.fixed_version.should eql version }
        it { @impediment.status.should eql issue_status1 }
        it { @impediment.tracker.should eql tracker_task }
        it { @impediment.assigned_to.should eql user }
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].issue_to.should eql feature }
        it { @impediment.relations_from[0].relation_type.should eql IssueRelation::TYPE_BLOCKS }
      end
    end
  end

end