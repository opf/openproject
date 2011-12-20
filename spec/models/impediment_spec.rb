require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Impediment do
  let(:user) { @user ||= Factory.create(:user) }
  let(:role) { @role ||= Factory.create(:role) }
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
  let(:version) { Factory.create(:version, :project => project) }

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
  let(:impediment) { Factory.build(:impediment, :author => user,
                                                :fixed_version => version,
                                                :assigned_to => user,
                                                :priority => issue_priority,
                                                :project => project,
                                                :tracker => tracker_task,
                                                :status => issue_status1)}

  before(:each) do
    Rails.cache.clear
    Setting.plugin_backlogs = {:points_burn_direction => "down",
                               :wiki_template => "",
                               :card_spec => "Sattleford VM-5040",
                               :story_trackers => [tracker_feature.id.to_s],
                               :task_tracker => tracker_task.id.to_s }

    User.current = user
    issue_priority.save
    issue_status1.save
    project.save
    tracker_workflow.save
  end

  describe "class methods" do
    describe :create_with_relationships do
      before(:each) do
        @impediment_subject = "Impediment A"
        role.permissions = [:create_impediments]
        role.save
      end

      shared_examples_for "impediment creation" do
        it { @impediment.subject.should eql @impediment_subject }
        it { @impediment.author.should eql User.current }
        it { @impediment.project.should eql project }
        it { @impediment.fixed_version.should eql version }
        it { @impediment.priority.should eql issue_priority}
        it { @impediment.status.should eql issue_status1 }
        it { @impediment.tracker.should eql tracker_task }
        it { @impediment.assigned_to.should eql user }
      end

      shared_examples_for "impediment creation with 1 blocking relationship" do
        it_should_behave_like "impediment creation"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].issue_to.should eql feature }
        it { @impediment.relations_from[0].relation_type.should eql IssueRelation::TYPE_BLOCKS }
      end

      shared_examples_for "impediment creation with no blocking relationship" do
        it_should_behave_like "impediment creation"
        it { @impediment.should have(0).relations_from }
      end

      describe "WITH a blocking relationship to a story" do
        describe "WITH the story having the same version" do
          before(:each) do
            feature.fixed_version = version
            feature.save
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => feature.id.to_s,
                                                                :status_id => issue_status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)

          end

          it_should_behave_like "impediment creation with 1 blocking relationship"
          it { @impediment.should_not be_new_record }
          it { @impediment.relations_from[0].should_not be_new_record }
        end

        describe "WITH the story having another version" do
          before(:each) do
            feature.fixed_version = Factory.create(:version, :project => project, :name => "another version")
            feature.save
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => feature.id.to_s,
                                                                :status_id => issue_status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)
          end

          it_should_behave_like "impediment creation with no blocking relationship"
          it { @impediment.should be_new_record }
          it { @impediment.errors[:blocks_ids].should eql I18n.t(:can_only_contain_issues_of_current_sprint, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
        end

        describe "WITH the story being non existent" do
          before(:each) do
            @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                                :assigned_to_id => user.id,
                                                                :blocks_ids => "0",
                                                                :status_id => issue_status1.id,
                                                                :fixed_version_id => version.id},
                                                                project.id)
          end

          it_should_behave_like "impediment creation with no blocking relationship"
          it { @impediment.should be_new_record }
          it { @impediment.errors[:blocks_ids].should eql I18n.t(:can_only_contain_issues_of_current_sprint, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
        end
      end

      describe "WITHOUT a blocking relationship defined" do
        before(:each) do
          @impediment = Impediment.create_with_relationships({:subject => @impediment_subject,
                                                              :assigned_to_id => user.id,
                                                              :blocks_ids => "",
                                                              :status_id => issue_status1.id,
                                                              :fixed_version_id => version.id},
                                                              project.id)
        end

        it_should_behave_like "impediment creation with no blocking relationship"
        it { @impediment.should be_new_record }
        it { @impediment.errors[:blocks_ids].should eql I18n.t(:must_block_at_least_one_issue, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
      end
    end
  end

  describe "instance methods" do
    describe :update_with_relationships do
      before(:each) do
        role.permissions = [:update_impediments]
        role.save

        feature.fixed_version = version
        feature.save

        @impediment = impediment
        @impediment.blocks_ids = feature.id.to_s
        @impediment.save
      end

      shared_examples_for "impediment update" do
        it { @impediment.author.should eql user }
        it { @impediment.project.should eql project }
        it { @impediment.fixed_version.should eql version }
        it { @impediment.priority.should eql issue_priority}
        it { @impediment.status.should eql issue_status1 }
        it { @impediment.tracker.should eql tracker_task }
        it { @impediment.blocks_ids.should eql @blocks.split(/\D+/).map{|id| id.to_i} }
      end

      shared_examples_for "impediment update with changed blocking relationship" do
        it_should_behave_like "impediment update"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].should_not be_new_record }
        it { @impediment.relations_from[0].issue_to.should eql @story }
        it { @impediment.relations_from[0].relation_type.should eql IssueRelation::TYPE_BLOCKS }
      end

      shared_examples_for "impediment update with unchanged blocking relationship" do
        it_should_behave_like "impediment update"
        it { @impediment.should have(1).relations_from }
        it { @impediment.relations_from[0].should_not be_changed }
        it { @impediment.relations_from[0].issue_to.should eql feature }
        it { @impediment.relations_from[0].relation_type.should eql IssueRelation::TYPE_BLOCKS }
      end

      describe "WHEN changing the blocking relationship to another story" do
        before(:each) do
          @story = Factory.build(:issue, :subject => "another story",
                                         :tracker => tracker_feature,
                                         :project => project,
                                         :author => user,
                                         :priority => issue_priority,
                                         :status => issue_status1)
        end

        describe "WITH the story having the same version" do
          before(:each) do
            @story.fixed_version = version
            @story.save
            @blocks = @story.id.to_s
            @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                   :status_id => issue_status1.id.to_s})
          end

          it_should_behave_like "impediment update with changed blocking relationship"
          it { @impediment.should_not be_changed }
        end

        describe "WITH the story having another version" do
          before(:each) do
            @story.fixed_version = Factory.create(:version, :project => project, :name => "another version")
            @story.save
            @blocks = @story.id.to_s
            @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                            :status_id => issue_status1.id.to_s})
          end

          it_should_behave_like "impediment update with unchanged blocking relationship"
          it "should not be saved successfully" do
            @saved.should be_false
          end
          it { @impediment.errors[:blocks_ids].should eql I18n.t(:can_only_contain_issues_of_current_sprint, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
        end

        describe "WITH the story beeing non existent" do
          before(:each) do
            @blocks = "0"
            @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                            :status_id => issue_status1.id.to_s})
          end

          it_should_behave_like "impediment update with unchanged blocking relationship"
          it "should not be saved successfully" do
            @saved.should be_false
          end
          it { @impediment.errors[:blocks_ids].should eql I18n.t(:can_only_contain_issues_of_current_sprint, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
        end
      end

      describe "WITHOUT a blocking relationship defined" do
        before(:each) do
          @blocks = ""
          @saved = @impediment.update_with_relationships({:blocks_ids => @blocks,
                                                          :status_id => issue_status1.id.to_s})
        end

        it_should_behave_like "impediment update with unchanged blocking relationship"
        it "should not be saved successfully" do
          @saved.should be_false
        end

        it { @impediment.errors[:blocks_ids].should eql I18n.t(:must_block_at_least_one_issue, :scope => [:activerecord, :errors, :models, :issue, :attributes, :blocks_ids]) }
      end
    end

    describe "blocks_ids=/blocks_ids" do
      describe "WITH an integer" do
        it do
          impediment.blocks_ids = 2
          impediment.blocks_ids.should eql [2]
        end
      end

      describe "WITH a string" do
        it do
          impediment.blocks_ids = "1, 2, 3"
          impediment.blocks_ids.should eql [1,2,3]
        end
      end

      describe "WITH an array" do
        it do
          impediment.blocks_ids = [1,2,3]
          impediment.blocks_ids.should eql [1,2,3]
        end
      end

      describe "WITH only prior blockers defined" do
        before(:each) do
          feature.fixed_version = version
          feature.save
          task.fixed_version = version
          task.save

          impediment.relations_from = [IssueRelation.new(:issue_from => impediment, :issue_to => feature, :relation_type => IssueRelation::TYPE_BLOCKS),
                                       IssueRelation.new(:issue_from => impediment, :issue_to => task, :relation_type => IssueRelation::TYPE_BLOCKS)]
          true
        end

        it { impediment.blocks_ids.should eql [feature.id, task.id] }
      end
    end
  end
end
