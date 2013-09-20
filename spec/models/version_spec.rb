require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  it { should have_many :version_settings }

  describe 'rebuild positions' do
    def build_issue(options = {})
      FactoryGirl.build(:issue, options.reverse_merge(:fixed_version_id => version.id,
                                                  :priority_id      => priority.id,
                                                  :project_id       => project.id,
                                                  :status_id        => status.id))
    end

    def create_issue(options = {})
      build_issue(options).tap { |i| i.save! }
    end

    let(:status)   { FactoryGirl.create(:issue_status)    }
    let(:priority) { FactoryGirl.create(:priority_normal) }
    let(:project)  { FactoryGirl.create(:project)         }

    let(:epic_type)  { FactoryGirl.create(:type, :name => 'Epic') }
    let(:story_type) { FactoryGirl.create(:type, :name => 'Story') }
    let(:task_type)  { FactoryGirl.create(:type, :name => 'Task')  }
    let(:other_type) { FactoryGirl.create(:type, :name => 'Other') }

    let(:version) { FactoryGirl.create(:version, :project_id => project.id, :name => 'Version') }

    before do
      # had problems while writing these specs, that some elements kept creaping
      # around between tests. This should be fast enough to not harm anybody
      # while adding an additional safety net to make sure, that everything runs
      # in isolation.
      Issue.delete_all
      IssuePriority.delete_all
      IssueStatus.delete_all
      Project.delete_all
      Type.delete_all
      Version.delete_all

      # enable and configure backlogs
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      Setting.plugin_openproject_backlogs = {"story_types" => [epic_type.id, story_type.id],
                                 "task_type"   => task_type.id}

      # otherwise the type id's from the previous test are still active
      Issue.instance_variable_set(:@backlogs_types, nil)

      project.types = [epic_type, story_type, task_type, other_type]
      version
    end

    it 'moves an issue to a project where backlogs is disabled while using versions' do
      project2 = FactoryGirl.create(:project, :name => "Project 2")
      project2.enabled_module_names = project2.enabled_module_names - ["backlogs"]
      project2.save!
      project2.reload

      issue1 = FactoryGirl.create(:issue, :type_id => task_type.id, :status_id => status.id, :project_id => project.id)
      issue2 = FactoryGirl.create(:issue, :parent_issue_id => issue1.id, :type_id => task_type.id, :status_id => status.id, :project_id => project.id)
      issue3 = FactoryGirl.create(:issue, :parent_issue_id => issue2.id, :type_id => task_type.id, :status_id => status.id, :project_id => project.id)

      issue1.reload
      issue1.fixed_version_id = version.id
      issue1.save!

      issue1.reload
      issue2.reload
      issue3.reload

      issue3.move_to_project(project2)

      issue1.reload
      issue2.reload
      issue3.reload

      issue2.move_to_project(project2)

      issue1.reload
      issue2.reload
      issue3.reload

      issue3.project.should == project2
      issue2.project.should == project2
      issue1.project.should == project

      issue3.fixed_version_id.should be_nil
      issue2.fixed_version_id.should be_nil
      issue1.fixed_version_id.should == version.id
    end

    it 'rebuilds postions' do
      e1 = create_issue(:type_id => epic_type.id)
      s2 = create_issue(:type_id => story_type.id)
      s3 = create_issue(:type_id => story_type.id)
      s4 = create_issue(:type_id => story_type.id)
      s5 = create_issue(:type_id => story_type.id)
      t3 = create_issue(:type_id => task_type.id)
      o9 = create_issue(:type_id => other_type.id)

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
