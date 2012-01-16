require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  it { should have_many :version_settings }

  describe 'rebuild positions' do
    def build_issue(options = {})
      Factory.build(:issue, options.reverse_merge(:fixed_version_id => version.id,
                                                  :priority_id      => priority.id,
                                                  :project_id       => project.id,
                                                  :status_id        => status.id))
    end

    def create_issue(options = {})
      build_issue(options).tap { |i| i.save! }
    end

    let(:status)   { Factory.create(:issue_status)    }
    let(:priority) { Factory.create(:priority_normal) }
    let(:project)  { Factory.create(:project)         }

    let(:epic_tracker)  { Factory.create(:tracker, :name => 'Epic') }
    let(:story_tracker) { Factory.create(:tracker, :name => 'Story') }
    let(:task_tracker)  { Factory.create(:tracker, :name => 'Task')  }
    let(:other_tracker) { Factory.create(:tracker, :name => 'Other') }

    let(:version) { Factory.create(:version, :project_id => project.id, :name => 'Version') }

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
      Setting.plugin_backlogs = {"story_trackers" => [epic_tracker.id, story_tracker.id],
                                 "task_tracker"   => task_tracker.id}

      # otherwise the tracker id's from the previous test are still active
      Issue.instance_variable_set(:@backlogs_trackers, nil)

      project.trackers = [epic_tracker, story_tracker, task_tracker, other_tracker]
      version
    end

    it 'rebuilds postions' do
      e1 = create_issue(:tracker_id => epic_tracker.id)
      s2 = create_issue(:tracker_id => story_tracker.id)
      s3 = create_issue(:tracker_id => story_tracker.id)
      s4 = create_issue(:tracker_id => story_tracker.id)
      s5 = create_issue(:tracker_id => story_tracker.id)
      t3 = create_issue(:tracker_id => task_tracker.id)
      o9 = create_issue(:tracker_id => other_tracker.id)

      [e1, s2, s3, s4, s5].each(&:move_to_bottom)

      # messing around with positions
      s3.send :assume_not_in_list
      s4.send :assume_not_in_list

      t3.send(:update_attribute_silently, :position, 3)
      o9.send(:update_attribute_silently, :position, 9)

      version.rebuild_positions(project)

      issues = version.fixed_issues.find(:all, :conditions => {:project_id => project}, :order => 'COALESCE(position, 0) ASC, id ASC')

      issues.map(&:position).should == [nil, nil, 1, 2, 3, 4, 5]
      issues.map(&:subject).should == [t3, o9, e1, s2, s5, s3, s4].map(&:subject)

      issues.map(&:subject).uniq.size.should == 7 # makes sure, that all issue
            # subjects are uniq, so that the above assertion works as expected
    end
  end
end
