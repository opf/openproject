require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  it { should have_many :version_settings }

  describe 'rebuild positions' do
    def build_issue(options = {})
      Factory.build(:issue, options.reverse_merge(:fixed_version_id => version.id,
                                                  :priority_id      => priority.id,
                                                  :project_id       => project.id,
                                                  :status_id        => status.id,
                                                  :tracker_id       => tracker.id))
    end

    def create_issue(options = {})
      build_issue(options).tap { |i| i.save! }
    end

    let(:status)   { Factory.create(:issue_status)    }
    let(:priority) { Factory.create(:priority_normal) }
    let(:project)  { Factory.create(:project)         }

    let(:tracker) { Factory.create(:tracker, :name => 'Tracker')    }

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
      Setting.plugin_redmine_backlogs = {:story_trackers => [tracker.id],
                                         :task_tracker   => nil}

      # otherwise the tracker id's from the previous test are still active
      Issue.instance_variable_set(:@backlogs_trackers, nil)

      project.trackers = [tracker]
      version
    end

    it 'rebuilds postions' do
      i1 = create_issue
      i2 = create_issue
      i3 = create_issue
      i4 = create_issue
      i5 = create_issue

      [i1, i2, i3, i4, i5].each(&:move_to_bottom)

      [i3, i4].map(&:assume_not_in_list)

      version.rebuild_positions(project)

      issues = version.fixed_issues.find(:all, :conditions => {:project_id => project}, :order => 'position')

      issues.map(&:position).should == [1, 2, 3, 4, 5]
      issues.map(&:subject).should == [i1, i2, i5, i3, i4].map(&:subject)

      issues.map(&:subject).uniq.size.should == 5 # makes sure, that all issue
            # subjects are uniq, so that the above assertion works as expected
    end
  end
end
