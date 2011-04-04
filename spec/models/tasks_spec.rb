require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Task do
  let(:user) { @user ||= Factory.create(:user) }
  let(:tracker_feature) { @tracker_feature ||= Factory.create(:tracker_feature) }
  let(:tracker_task) { @tracker_task ||= Factory.create(:tracker_task) }
  let(:issue_priority) { @issue_priority ||= Factory.create(:priority) }
  let(:task) { Factory.build(:task, :tracker => tracker_task,
                                     :project => project,
                                     :author => user,
                                     :priority => issue_priority,
                                     :status => issue_status) }
  let(:feature) { Factory.build(:issue, :tracker => tracker_feature,
                                        :project => project,
                                        :author => user,
                                        :priority => issue_priority,
                                        :status => issue_status) }
  let(:version) { @version ||= Factory.create(:version, :project => project) }
  let(:project) { @project ||= Factory.create(:project) }
  let(:issue_status) { @status ||= Factory.create(:issue_status) }

  before(:each) do
    Setting.plugin_redmine_backlogs  = {"points_burn_direction" => "down",
                                        "wiki_template" => "",
                                        "card_spec" => "Sattleford VM-5040",
                                        :story_trackers => [tracker_feature.id.to_s],
                                        :task_tracker => tracker_task.id.to_s }
  end

  describe "Instance Methods" do
    before(:each) do

    end

    describe :impediment? do
      describe "WITHOUT parent" do
        before(:each) do
        end

        it { task.should be_impediment }
      end

      describe "WITH parent" do
        before(:each) do
          feat = feature
          feat.save
          task.parent_issue_id = feat.id
        end

        it { task.should_not be_impediment }
      end
    end
  end
end