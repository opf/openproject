require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do
  describe 'Story positions' do
    def build_issue(options)
      Factory.build(:issue, options.reverse_merge(:fixed_version_id => sprint_1.id,
                                                  :priority_id      => priority.id,
                                                  :project_id       => project.id,
                                                  :status_id        => status.id,
                                                  :tracker_id       => story_tracker.id))
    end

    def create_issue(options)
      build_issue(options).tap { |i| i.save! }
    end

    let(:status)   { Factory.create(:issue_status)    }
    let(:priority) { Factory.create(:priority_normal) }
    let(:project)  { Factory.create(:project)         }

    let(:story_tracker) { Factory.create(:tracker, :name => 'Story')    }
    let(:epic_tracker)  { Factory.create(:tracker, :name => 'Epic')     }
    let(:task_tracker)  { Factory.create(:tracker, :name => 'Task')     }
    let(:other_tracker) { Factory.create(:tracker, :name => 'Feedback') }

    let(:sprint_1) { Factory.create(:version, :project_id => project.id, :name => 'Sprint 1') }
    let(:sprint_2) { Factory.create(:version, :project_id => project.id, :name => 'Sprint 2') }

    let(:issue_1) { create_issue(:subject => 'Issue 1', :fixed_version_id => sprint_1.id) }
    let(:issue_2) { create_issue(:subject => 'Issue 2', :fixed_version_id => sprint_1.id) }
    let(:issue_3) { create_issue(:subject => 'Issue 3', :fixed_version_id => sprint_1.id) }
    let(:issue_4) { create_issue(:subject => 'Issue 4', :fixed_version_id => sprint_1.id) }
    let(:issue_5) { create_issue(:subject => 'Issue 5', :fixed_version_id => sprint_1.id) }

    let(:issue_a) { create_issue(:subject => 'Issue a', :fixed_version_id => sprint_2.id) }
    let(:issue_b) { create_issue(:subject => 'Issue b', :fixed_version_id => sprint_2.id) }
    let(:issue_c) { create_issue(:subject => 'Issue c', :fixed_version_id => sprint_2.id) }

    let(:feedback_1)  { create_issue(:subject => 'Feedback 1', :fixed_version_id => sprint_1.id,
                                                               :tracker_id => other_tracker.id) }

    let(:task_1)  { create_issue(:subject => 'Task 1', :fixed_version_id => sprint_1.id,
                                                       :tracker_id => task_tracker.id) }

    before do
      # had problems while writing these specs, that some elements kept creaping
      # around between tests. This should be fast enough to not harm anybody
      # while adding an additional safety net to make sure, that everything runs
      # in isolation.
      Issue.delete_all
      IssuePriority.delete_all
      IssueStatus.delete_all
      Project.delete_all
      Tracker.delete_all
      Version.delete_all

      # enable and configure backlogs
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      Setting.plugin_redmine_backlogs = {:story_trackers => [story_tracker.id, epic_tracker.id],
                                         :task_tracker   => task_tracker.id}

      Issue.instance_variable_set(:@backlogs_trackers, nil)

      project.trackers = [story_tracker, epic_tracker, task_tracker, other_tracker]
      sprint_1
      sprint_2

      # create and order issues
      issue_1.move_to_bottom
      issue_2.move_to_bottom
      issue_3.move_to_bottom
      issue_4.move_to_bottom
      issue_5.move_to_bottom

      issue_a.move_to_bottom
      issue_b.move_to_bottom
      issue_c.move_to_bottom
    end

    describe '- Creating an issue in a sprint' do
      it 'adds it to the top of the list' do
        new_issue = create_issue(:subject => 'Newest Issue', :fixed_version_id => sprint_1.id)

        new_issue.should_not be_new_record
        new_issue.should be_first
      end

      it 'reorders the existing issues' do
        new_issue = create_issue(:subject => 'Newest Issue', :fixed_version_id => sprint_1.id)

        [issue_1, issue_2, issue_3, issue_4, issue_5].each(&:reload).map(&:position).should == [2, 3, 4, 5, 6]
      end
    end

    describe '- Removing an issue from the sprint' do
      it 'reorders the remaining issues' do
        issue_2.fixed_version = sprint_2
        issue_2.save!

        sprint_1.fixed_issues.should == [issue_1, issue_3, issue_4, issue_5]
        sprint_1.fixed_issues.each(&:reload).map(&:position).should == [1, 2, 3, 4]
      end
    end

    describe '- Adding an issue to a sprint' do
      it 'adds it to the top of the list' do
        issue_a.fixed_version = sprint_1
        issue_a.save!

        issue_a.should be_first
      end

      it 'reorders the existing issues' do
        issue_a.fixed_version = sprint_1
        issue_a.save!

        [issue_1, issue_2, issue_3, issue_4, issue_5].each(&:reload).map(&:position).should == [2, 3, 4, 5, 6]
      end
    end
    
    describe '- Deleting an issue in a sprint' do
      it 'reorders the existing issues' do
        issue_3.destroy

        [issue_1, issue_2, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4]
      end
    end

    describe '- Changing the tracker' do
      describe 'by moving a story to another story tracker' do
        it 'keeps all positions in the sprint in tact' do
          issue_3.tracker = epic_tracker
          issue_3.save!

          [issue_1, issue_2, issue_3, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4, 5]
        end
      end

      describe 'by moving a story to a non-backlogs tracker' do
        it 'removes it from any list' do
          issue_3.tracker = other_tracker
          issue_3.save!

          issue_3.should_not be_in_list
        end

        it 'reorders the remaining stories' do
          issue_3.tracker = other_tracker
          issue_3.save!

          [issue_1, issue_2, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4]
        end
      end
      
      describe 'by moving a story to the task tracker' do
        it 'removes it from any list' do
          issue_3.tracker = task_tracker
          issue_3.save!

          issue_3.should_not be_in_list
        end

        it 'reorders the remaining stories' do
          issue_3.tracker = task_tracker
          issue_3.save!

          [issue_1, issue_2, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4]
        end
      end

      describe 'by moving a task to the story tracker' do
        it 'adds it to the top of the list' do
          task_1.tracker = story_tracker
          task_1.save!

          task_1.should be_first
        end

        it 'reorders the existing stories' do
          task_1.tracker = story_tracker
          task_1.save!

          [task_1, issue_1, issue_2, issue_3, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4, 5, 6]
        end
      end

      describe 'by moving a non-backlogs issue to a story tracker' do
        it 'adds it to the top of the list' do
          feedback_1.tracker = story_tracker
          feedback_1.save!

          feedback_1.should be_first
        end

        it 'reorders the existing stories' do
          feedback_1.tracker = story_tracker
          feedback_1.save!

          [feedback_1, issue_1, issue_2, issue_3, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4, 5, 6]
        end
      end
    end

    describe '- Moving issues between projects' do
      # N.B.: You cannot move a ticket to another project and change the
      # fixed_version at the same time. OTOH chiliproject tries to keep
      # the fixed_version if possible (e.g. within project hierarchies with
      # shared versions)

      let(:project_wo_backlogs) { Factory.create(:project) }
      let(:sub_project_wo_backlogs) { Factory.create(:project) }

      let(:shared_sprint)   { Factory.create(:version,
                                             :project_id => project.id,
                                             :name => 'Shared Sprint',
                                             :sharing => 'descendants') }

      let(:version_go_live) { Factory.create(:version,
                                             :project_id => project_wo_backlogs.id,
                                             :name => 'Go-Live') }

      before do
        project_wo_backlogs.enabled_module_names = project_wo_backlogs.enabled_module_names - ["backlogs"]
        sub_project_wo_backlogs.enabled_module_names = sub_project_wo_backlogs.enabled_module_names - ["backlogs"]

        project_wo_backlogs.trackers = [story_tracker, task_tracker, other_tracker]
        sub_project_wo_backlogs.trackers = [story_tracker, task_tracker, other_tracker]

        sub_project_wo_backlogs.move_to_child_of(project)

        shared_sprint
        version_go_live
      end

      describe '- Moving an issue from a project without backlogs to a backlogs_enabled project' do
        describe 'if the fixed_version may not be kept' do
          let(:issue_i) { create_issue(:subject => 'Issue I',
                                       :fixed_version_id => version_go_live.id,
                                       :project_id => project_wo_backlogs.id) }
          before do
            issue_i
          end

          it 'sets the fixed_version_id to nil' do
            result = issue_i.move_to_project(project)

            result.should be_true

            issue_i.fixed_version.should be_nil
          end

          it 'removes it from any list' do
            result = issue_i.move_to_project(project)

            result.should be_true

            issue_i.should_not be_in_list
          end
        end

        describe 'if the fixed_version may be kept' do
          let(:issue_i) { create_issue(:subject => 'Issue I',
                                       :fixed_version_id => shared_sprint.id,
                                       :project_id => sub_project_wo_backlogs.id) }

          before do
            issue_i
          end

          it 'keeps the fixed_version_id' do
            result = issue_i.move_to_project(project)

            result.should be_true

            issue_i.fixed_version.should == shared_sprint
          end

          it 'adds it to the top of the list' do
            result = issue_i.move_to_project(project)

            result.should be_true

            issue_i.should be_first
          end
        end
      end

      describe '- Moving an issue away from backlogs_enabled project to a project without backlogs' do
        describe 'if the fixed_version may not be kept' do
          it 'sets the fixed_version_id to nil' do
            result = issue_3.move_to_project(project_wo_backlogs)

            result.should be_true

            issue_3.fixed_version.should be_nil
          end

          it 'removes it from any list' do
            result = issue_3.move_to_project(sub_project_wo_backlogs)

            result.should be_true

            issue_3.should_not be_in_list
          end

          it 'reorders the remaining issues' do
            result = issue_3.move_to_project(sub_project_wo_backlogs)

            result.should be_true

            [issue_1, issue_2, issue_4, issue_5].each(&:reload).map(&:position).should == [1, 2, 3, 4]
          end
        end

        describe 'if the fixed_version may be kept' do
          let(:issue_i)   { create_issue(:subject => 'Issue I',
                                         :fixed_version_id => shared_sprint.id) }
          let(:issue_ii)  { create_issue(:subject => 'Issue II',
                                         :fixed_version_id => shared_sprint.id) }
          let(:issue_iii) { create_issue(:subject => 'Issue III',
                                         :fixed_version_id => shared_sprint.id) }

          before do
            issue_i.move_to_bottom
            issue_ii.move_to_bottom
            issue_iii.move_to_bottom

            [issue_i, issue_ii, issue_iii].map(&:position).should == [1, 2, 3]
          end

          it 'keeps the fixed_version_id' do
            result = issue_ii.move_to_project(sub_project_wo_backlogs)

            result.should be_true

            issue_ii.fixed_version.should == shared_sprint
          end

          it 'removes it from any list' do
            result = issue_ii.move_to_project(sub_project_wo_backlogs)

            result.should be_true

            issue_ii.should_not be_in_list
          end

          it 'reorders the remaining issues' do
            result = issue_ii.move_to_project(sub_project_wo_backlogs)

            result.should be_true

            [issue_i, issue_iii].each(&:reload).map(&:position).should == [1, 2]
          end
        end
      end
    end
  end
end
