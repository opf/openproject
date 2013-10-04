require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def project_boundaries_spanning_work_package_hierarchy_allowed?
  work_package = WorkPackage.new
  work_package.project_id = 1
  parent_work_package = WorkPackage.new
  parent_work_package.project_id = 2
  work_package.parent = parent_work_package
  work_package.valid?
  work_package.errors[:parent_id].blank?
end

describe WorkPackage, 'parent-child relationships between backlogs stories and backlogs tasks are prohibited if they span project boundaries' do
  let(:type_feature) { FactoryGirl.build(:type_feature) }
  let(:type_task) { FactoryGirl.build(:type_task) }
  let(:type_bug) { FactoryGirl.build(:type_bug) }
  let(:version1) { project.versions.first }
  let(:version2) { project.versions.last }
  let(:role) { FactoryGirl.build(:role) }
  let(:user) { FactoryGirl.build(:user) }
  let(:issue_priority) { FactoryGirl.build(:priority) }
  let(:status) { FactoryGirl.build(:status, :name => "status 1", :is_default => true) }

  let(:parent_project) do
    p = FactoryGirl.build(:project, :name => "parent_project",
                                :members => [FactoryGirl.build(:member,
                                                           :principal => user,
                                                           :roles => [role])],
                                :types => [type_feature, type_task, type_bug])

    p.versions << FactoryGirl.build(:version, :name => "Version1", :project => p)
    p.versions << FactoryGirl.build(:version, :name => "Version2", :project => p)

    p
  end

  let(:child_project) do
    p = FactoryGirl.build(:project, :name => "child_project",
                                :members => [FactoryGirl.build(:member,
                                                           :principal => user,
                                                           :roles => [role])],
                                :types => [type_feature, type_task, type_bug])

    p.versions << FactoryGirl.build(:version, :name => "Version1", :project => p)
    p.versions << FactoryGirl.build(:version, :name => "Version2", :project => p)

    p
  end

  let(:story) { FactoryGirl.build(:work_package,
                              :subject => "Story",
                              :type => type_feature,
                              :status => status,
                              :author => user,
                              :priority => issue_priority) }

  let(:story2) { FactoryGirl.build(:work_package,
                               :subject => "Story2",
                               :type => type_feature,
                               :status => status,
                               :author => user,
                               :priority => issue_priority) }

  let(:task) { FactoryGirl.build(:work_package,
                             :subject => "Task",
                             :type => type_task,
                             :status => status,
                             :author => user,
                             :priority => issue_priority) }

   let(:task2) { FactoryGirl.build(:work_package,
                               :subject => "Task2",
                               :type => type_task,
                               :status => status,
                               :author => user,
                               :priority => issue_priority) }

   let(:bug) { FactoryGirl.build(:work_package,
                             :subject => "Bug",
                             :type => type_bug,
                             :status => status,
                             :author => user,
                             :priority => issue_priority) }

   let(:bug2) { FactoryGirl.build(:work_package,
                              :subject => "Bug2",
                              :type => type_bug,
                              :status => status,
                              :author => user,
                              :priority => issue_priority) }

  before do
    Setting.stub(:cross_project_work_package_relations).and_return("1")
  end

  before(:each) do
    parent_project.save!
    child_project.save!

    Setting.stub(:plugin_openproject_backlogs).and_return({"points_burn_direction" => "down",
                                                            "wiki_template"         => "",
                                                            "card_spec"             => "Sattleford VM-5040",
                                                            "story_types"           => [type_feature.id],
                                                            "task_type"             => type_task.id.to_s})
  end

  if project_boundaries_spanning_work_package_hierarchy_allowed?

  describe "WHEN creating the child" do

    shared_examples_for "restricted hierarchy on creation" do
      before(:each) do
        parent.project = parent_project
        parent.save

        child.parent_id = parent.id
      end

      describe "WITH the child in a different project" do
        before(:each) do
          child.project = child_project
        end

        it { child.should_not be_valid }
      end

      describe "WITH the child in the same project" do
        before(:each) do
          child.project = parent_project
        end

        it { child.should be_valid }
      end
    end

    shared_examples_for "unrestricted hierarchy on creation" do
      before(:each) do
        parent.project = parent_project
        parent.save

        child.parent_id = parent.id
      end

      describe "WITH the child in a different project" do
        before(:each) do
          child.project = child_project
        end

        it { child.should be_valid }
      end

      describe "WITH the child in the same project" do
        before(:each) do
          child.project = parent_project
        end

        it { child.should be_valid }
      end
    end

    describe "WITH backlogs enabled in both projects" do
      describe "WITH a story as parent" do
        let(:parent) { story }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "restricted hierarchy on creation"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end
      end

      describe "WITH a task as parent (with or without parent does not matter)" do
        let(:parent) { task }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "restricted hierarchy on creation"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end
      end

      describe "WITH a non backlogs work_package as parent" do
        let(:parent) { bug }

        describe "WITH a task as child" do
          let(:child) { task2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end

        describe "WITH a non backlogs work_package as child" do
          let(:child) { bug2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end

        describe "WITH a story as child" do
          let(:child) { story2 }

          it_should_behave_like "unrestricted hierarchy on creation"
        end
      end
    end
  end

  describe "WITH an existing child" do #this could happen when the project enables backlogs afterwards
    shared_examples_for "restricted hierarchy by enabling backlogs" do
      before(:each) do
        parent.project = parent_project
        parent.save

        child.parent_id = parent.id
      end

      describe "WITH the child in a different project" do
        before(:each) do
          child_project.enabled_module_names = child_project.enabled_module_names.find_all{|n| n != "backlogs" }
          child_project.save!
          child.project = child_project
          child_project.reload
          child.save!
          child_project.enabled_module_names = child_project.enabled_module_names + ["backlogs"]
          child_project.save!
        end

        it { child.reload.should_not be_valid }
        it { parent.reload.should_not be_valid }
      end

      describe "WITH the child in the same project" do
        before(:each) do
          parent_project.enabled_module_names = parent_project.enabled_module_names.find_all{|n| n != "backlogs" }
          parent_project.save!
          parent_project.reload
          child.project = parent_project
          child.save!
          parent_project.enabled_module_names = parent_project.enabled_module_names + ["backlogs"]
          parent_project.save!
        end

        it { child.reload.should be_valid }
        it { parent.reload.should be_valid }
      end
    end

    shared_examples_for "unrestricted hierarchy even when enabling backlogs" do
      before(:each) do
        parent.project = parent_project
        parent.save

        child.parent_id = parent.id
      end

      describe "WITH the child in a different project" do
        before(:each) do
          child_project.enabled_module_names = child_project.enabled_module_names.find_all{|n| n != "backlogs" }
          child_project.save!
          child.project = child_project
          child.save!
          child_project.enabled_module_names = child_project.enabled_module_names + ["backlogs"]
          child_project.save!
        end

        it { child.reload.should be_valid }
        it { parent.reload.should be_valid }
      end

      describe "WITH the child in the same project" do
        before(:each) do
          parent_project.enabled_module_names = parent_project.enabled_module_names.find_all{|n| n != "backlogs" }
          parent_project.save!
          child.project = parent_project
          child.save!
          parent_project.enabled_module_names = parent_project.enabled_module_names + ["backlogs"]
          parent_project.save!
        end

        it { child.reload.should be_valid }
        it { parent.reload.should be_valid }
      end
    end

    describe "WITH a story as parent" do
      let(:parent) { story }

      describe "WITH a task as child" do
        let(:child) { task2 }

        it_should_behave_like "restricted hierarchy by enabling backlogs"
      end

      describe "WITH a non backlogs work_package as child" do
        let(:child) { bug2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end

      describe "WITH a story as child" do
        let(:child) { story2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end
    end

    describe "WITH a task as parent" do
      let(:parent) { task }

      describe "WITH a task as child" do
        let(:child) { task2 }

        it_should_behave_like "restricted hierarchy by enabling backlogs"
      end

      describe "WITH a non backlogs work_package as child" do
        let(:child) { bug2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end

      describe "WITH a story as child" do
        let(:child) { story2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end
    end

    describe "WITH a non-backlogs-work_package as parent" do
      let(:parent) { bug }

      describe "WITH a task as child" do
        let(:child) { task2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end

      describe "WITH a non backlogs work_package as child" do
        let(:child) { bug2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end

      describe "WITH a story as child" do
        let(:child) { story2 }

        it_should_behave_like "unrestricted hierarchy even when enabling backlogs"
      end
    end
  end
end
end
