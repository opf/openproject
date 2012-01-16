require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue, "changing a story's fixed_version changes the fixed_version of all it's tasks (and the tasks beyond)" do
  let(:tracker_feature) { Factory.build(:tracker_feature) }
  let(:tracker_task) { Factory.build(:tracker_task) }
  let(:tracker_bug) { Factory.build(:tracker_bug) }
  let(:version1) { project.versions.first }
  let(:version2) { project.versions.last }
  let(:role) { Factory.build(:role) }
  let(:user) { Factory.build(:user) }
  let(:issue_priority) { Factory.build(:priority) }
  let(:issue_status) { Factory.build(:issue_status, :name => "status 1", :is_default => true) }

  let(:project) do
    p = Factory.build(:project, :members => [Factory.build(:member,
                                                           :principal => user,
                                                           :roles => [role])],
                                :trackers => [tracker_feature, tracker_task, tracker_bug])

    p.versions << Factory.build(:version, :name => "Version1", :project => p)
    p.versions << Factory.build(:version, :name => "Version2", :project => p)

    p
  end

  let(:story) { Factory.build(:issue,
                              :subject => "Story",
                              :project => project,
                              :tracker => tracker_feature,
                              :fixed_version => version1,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:story2) { Factory.build(:issue,
                               :subject => "Story2",
                               :project => project,
                               :tracker => tracker_feature,
                               :fixed_version => version1,
                               :status => issue_status,
                               :author => user,
                               :priority => issue_priority) }

  let(:story3) { Factory.build(:issue,
                               :subject => "Story3",
                               :project => project,
                               :tracker => tracker_feature,
                               :fixed_version => version1,
                               :status => issue_status,
                               :author => user,
                               :priority => issue_priority) }

  let(:task) { Factory.build(:issue,
                             :subject => "Task",
                             :tracker => tracker_task,
                             :fixed_version => version1,
                             :project => project,
                             :status => issue_status,
                             :author => user,
                             :priority => issue_priority) }

  let(:task2) { Factory.build(:issue,
                              :subject => "Task2",
                              :tracker => tracker_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:task3) { Factory.build(:issue,
                              :subject => "Task3",
                              :tracker => tracker_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:task4) { Factory.build(:issue,
                              :subject => "Task4",
                              :tracker => tracker_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:task5) { Factory.build(:issue,
                              :subject => "Task5",
                              :tracker => tracker_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:task6) { Factory.build(:issue,
                              :subject => "Task6",
                              :tracker => tracker_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => issue_status,
                              :author => user,
                              :priority => issue_priority) }

  let(:bug) { Factory.build(:issue,
                            :subject => "Bug",
                            :tracker => tracker_bug,
                            :fixed_version => version1,
                            :project => project,
                            :status => issue_status,
                            :author => user,
                            :priority => issue_priority) }

  let(:bug2) { Factory.build(:issue,
                             :subject => "Bug2",
                             :tracker => tracker_bug,
                             :fixed_version => version1,
                             :project => project,
                             :status => issue_status,
                             :author => user,
                             :priority => issue_priority) }

  let(:bug3) { Factory.build(:issue,
                             :subject => "Bug3",
                             :tracker => tracker_bug,
                             :fixed_version => version1,
                             :project => project,
                             :status => issue_status,
                             :author => user,
                             :priority => issue_priority) }

  before(:each) do
    project.save!

    Setting.plugin_backlogs  = {"points_burn_direction" => "down",
                                "wiki_template"         => "",
                                "card_spec"             => "Sattleford VM-5040",
                                "story_trackers"        => [tracker_feature.id],
                                "task_tracker"          => tracker_task.id.to_s}

    # otherwise the tracker id's from the previous test are still active
    Issue.instance_variable_set(:@backlogs_trackers, nil)
  end

  def standard_child_layout
    # Layout is
    # child
    # -> task3
    # -> task4
    # -> bug3
    #   -> task5
    # -> story3
    #   -> task6
    task3.parent_issue_id = child.id
    task3.save!
    task4.parent_issue_id = child.id
    task4.save!
    bug3.parent_issue_id = child.id
    bug3.save!
    story3.parent_issue_id = child.id
    story3.save!

    task5.parent_issue_id = bug3.id
    task5.save!
    task6.parent_issue_id = story3.id
    task6.save!

    child.reload
  end


  describe "WHEN changing fixed_version" do

    shared_examples_for "changing parent's fixed_version changes child's fixed version" do

      it "SHOULD change the child's fixed version to the parent's fixed version" do
        subject.save!
        child.parent_issue_id = subject.id
        child.save!

        standard_child_layout

        subject.reload

        subject.fixed_version = version2
        subject.save!

        # due to performance, these assertions are all in one it statement
        child.reload.fixed_version.should eql version2
        task3.reload.fixed_version.should eql version2
        task4.reload.fixed_version.should eql version2
        bug3.reload.fixed_version.should eql version1
        story3.reload.fixed_version.should eql version1
        task5.reload.fixed_version.should eql version1
        task6.reload.fixed_version.should eql version1
      end
    end

    shared_examples_for "changing parent's fixed_version does not change child's fixed_version" do

      it "SHOULD keep the child's version" do
        subject.save!
        child.parent_issue_id = subject.id
        child.save!

        standard_child_layout

        subject.reload

        subject.fixed_version = version2
        subject.save!

        # due to performance, these assertions are all in one it statement
        child.reload.fixed_version.should eql version1
        task3.reload.fixed_version.should eql version1
        task4.reload.fixed_version.should eql version1
        bug3.reload.fixed_version.should eql version1
        story3.reload.fixed_version.should eql version1
        task5.reload.fixed_version.should eql version1
        task6.reload.fixed_version.should eql version1
      end
    end

    describe "WITH backlogs enabled" do

      describe "WITH a story" do
        subject { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing parent's fixed_version changes child's fixed version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a story as a child" do
          let(:child) { story2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end

      describe "WITH a task (impediment) without a parent" do
        subject { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing parent's fixed_version changes child's fixed version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end

      describe "WITH a non backlogs issue" do
        subject { bug }

        describe "WITH a task as child" do
          let(:child) { task }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a story as a child" do
          let(:child) { story }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end
    end

    describe "WITH backlogs disabled" do
      before(:each) do
        project.enabled_module_names = project.enabled_module_names.find_all{|n| n != "backlogs" }
      end

      describe "WITH a story" do
        subject { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a story as a child" do
          let(:child) { story2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end

      describe "WITH a task" do
        before(:each) do
          bug2.save!
          task.parent_issue_id = bug2.id # so that it is considered a task
          task.save!
        end

        subject { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end

      describe "WITH a task (impediment) without a parent" do
        subject { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end

      describe "WITH a non backlogs issue" do
        subject { bug }

        describe "WITH a task as child" do
          let(:child) { task }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a non backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end

        describe "WITH a story as a child" do
          let(:child) { story }

          it_should_behave_like "changing parent's fixed_version does not change child's fixed_version"
        end
      end
    end
  end

  describe "WHEN changing the parent_issue_id" do
    shared_examples_for "changing the child's parent_issue to the parent changes child's fixed version" do

      it "SHOULD change the child's fixed version to the parent's fixed version" do
        child.save!
        standard_child_layout

        parent.fixed_version = version2
        parent.save!
        child.parent_issue_id = parent.id
        child.save!

        # due to performance, these assertions are all in one it statement
        child.reload.fixed_version.should eql version2
        task3.reload.fixed_version.should eql version2
        task4.reload.fixed_version.should eql version2
        bug3.reload.fixed_version.should eql version1
        story3.reload.fixed_version.should eql version1
        task5.reload.fixed_version.should eql version1
        task6.reload.fixed_version.should eql version1
      end
    end

    shared_examples_for "changing the child's parent_issue to the parent leaves child's fixed version" do

      it "SHOULD keep the child's version" do
        child.save!
        standard_child_layout

        parent.fixed_version = version2
        parent.save!
        child.parent_issue_id = parent.id
        child.save!

        # due to performance, these assertions are all in one it statement
        child.reload.fixed_version.should eql version1
        task3.reload.fixed_version.should eql version1
        task4.reload.fixed_version.should eql version1
        bug3.reload.fixed_version.should eql version1
        story3.reload.fixed_version.should eql version1
        task5.reload.fixed_version.should eql version1
        task6.reload.fixed_version.should eql version1
      end
    end

    describe "WITH backogs enabled" do
      describe "WITH a story as parent" do
        let(:parent) { story }

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing the child's parent_issue to the parent changes child's fixed version"
        end

        describe "WITH a non-backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end
      end

      describe "WITH a task as parent" do
        before(:each) do
          story.save!
          task.parent_issue_id = story.id
          task.save!
          story.reload
          task.reload
        end

        let(:parent) { story } # needs to be the story because it is not possible to change a task's fixed_version_id

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing the child's parent_issue to the parent changes child's fixed version"
        end

        describe "WITH a non-backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end
      end

      describe "WITH an impediment (task) as parent" do
        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing the child's parent_issue to the parent changes child's fixed version"
        end

        describe "WITH a non-backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end
      end

      describe "WITH a non-backlogs issue as parent" do
        let(:parent) { bug }

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end

        describe "WITH a non-backlogs issue as child" do
          let(:child) { bug2 }

          it_should_behave_like "changing the child's parent_issue to the parent leaves child's fixed version"
        end
      end
    end
  end
end
