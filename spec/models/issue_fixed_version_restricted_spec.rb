require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage, "fixed version restricted by an work_package parents (if it's a task)" do
  let(:type_feature) { FactoryGirl.build(:type_feature) }
  let(:type_task) { FactoryGirl.build(:type_task) }
  let(:type_bug) { FactoryGirl.build(:type_bug) }
  let(:version1) { project.versions.first }
  let(:version2) { project.versions.last }
  let(:role) { FactoryGirl.build(:role) }
  let(:user) { FactoryGirl.build(:user) }
  let(:issue_priority) { FactoryGirl.build(:priority) }
  let(:status) { FactoryGirl.build(:status, :name => "status 1", :is_default => true) }

  let(:project) do
    p = FactoryGirl.build(:project, :members => [FactoryGirl.build(:member,
                                                           :principal => user,
                                                           :roles => [role])],
                                :types => [type_feature, type_task, type_bug])

    p.versions << FactoryGirl.build(:version, :name => "Version1", :project => p)
    p.versions << FactoryGirl.build(:version, :name => "Version2", :project => p)

    p
  end


  let(:story) do
    story = FactoryGirl.build(:work_package,
                              :subject => "Story",
                              :project => project,
                              :type => type_feature,
                              :fixed_version => version1,
                              :status => status,
                              :author => user,
                              :priority => issue_priority)
    story.project.enabled_module_names += ["backlogs"]
    story
  end

  let(:story2) do
    story = FactoryGirl.build(:work_package,
                              :subject => "Story2",
                              :project => project,
                              :type => type_feature,
                              :fixed_version => version1,
                              :status => status,
                              :author => user,
                              :priority => issue_priority)
    story.project.enabled_module_names += ["backlogs"]
    story
  end


  let(:task) { FactoryGirl.build(:work_package,
                             :subject => "Task",
                             :type => type_task,
                             :fixed_version => version1,
                             :project => project,
                             :status => status,
                             :author => user,
                             :priority => issue_priority) }

  let(:task2) { FactoryGirl.build(:work_package,
                              :subject => "Task2",
                              :type => type_task,
                              :fixed_version => version1,
                              :project => project,
                              :status => status,
                              :author => user,
                              :priority => issue_priority) }

  let(:bug) { FactoryGirl.build(:work_package,
                            :subject => "Bug",
                            :type => type_bug,
                            :fixed_version => version1,
                            :project => project,
                            :status => status,
                            :author => user,
                            :priority => issue_priority) }

  let(:bug2) { FactoryGirl.build(:work_package,
                             :subject => "Bug2",
                             :type => type_bug,
                             :fixed_version => version1,
                             :project => project,
                             :status => status,
                             :author => user,
                             :priority => issue_priority) }

  shared_examples_for "fixed version beeing inherited from the parent" do

    before(:each) do
      parent.save!
      subject.parent_id = parent.id unless subject.parent_id.present? #already set outside the example group?
      subject.save!
      parent.reload
    end

    describe "WITHOUT a fixed version and the parent also having no fixed version" do
      before(:each) do
        parent.fixed_version = nil
        parent.save!
        subject.reload
        subject.fixed_version = nil
        subject.save!
      end

      it { subject.reload.fixed_version.should be_nil }
    end

    describe "WITHOUT a fixed version and the parent having a fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = nil
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end

    describe "WITH a fixed version and the parent having a different fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = version2
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end

    describe "WITH a fixed version and the parent having the same fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = version1
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end

    describe "WITH a fixed version and the parent having no fixed version" do
      before(:each) do
        parent.fixed_version = nil
        parent.save!
        subject.reload
        subject.fixed_version = version1
        subject.save!
      end

      it { subject.reload.fixed_version.should be_nil }
    end
  end

  shared_examples_for "fixed version not beeing inherited from the parent" do

    before(:each) do
      parent.save!
      subject.parent_id = parent.id unless subject.parent_id.present? #already set outside the example group?
      subject.save!
      parent.reload
    end

    describe "WITHOUT a fixed version and the parent also having no fixed version" do
      before(:each) do
        parent.fixed_version = nil
        parent.save!
        subject.reload
        subject.fixed_version = nil
        subject.save!
      end

      it { subject.reload.fixed_version.should be_nil }
    end

    describe "WITHOUT a fixed version and the parent having a fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = nil
        subject.save!
      end

      it { subject.reload.fixed_version.should be_nil }
    end

    describe "WITH a fixed version and the parent having a different fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = version2
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version2 }
    end

    describe "WITH a fixed version and the parent having the same fixed version" do
      before(:each) do
        parent.fixed_version = version1
        parent.save!
        subject.fixed_version = version1
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end

    describe "WITH a fixed version and the parent having no fixed version" do
      before(:each) do
        parent.fixed_version = nil
        parent.save!
        subject.reload
        subject.fixed_version = version1
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end
  end

  shared_examples_for "fixed version without restriction" do
    describe "WITHOUT a fixed version" do
      before(:each) do
        subject.fixed_version = nil
        subject.save!
      end

      it { subject.reload.fixed_version.should be_nil }
    end

    describe "WITH a fixed version" do
      before(:each) do
        subject.fixed_version = version1
        subject.save!
      end

      it { subject.reload.fixed_version.should eql version1 }
    end
  end

  before(:each) do
    project.save!

    Setting.stub(:plugin_openproject_backlogs).and_return({"points_burn_direction" => "down",
                                                            "wiki_template"         => "",
                                                            "card_spec"             => "Sattleford VM-5040",
                                                            "story_types"           => [type_feature.id],
                                                            "task_type"             => type_task.id.to_s})
  end

  describe "WITH a story" do
    subject { story }

    describe "WITHOUT a parent work_package" do
      it_should_behave_like "fixed version without restriction"
    end

    describe "WITH a story as it's parent" do
      let(:parent) { story2 }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end

    describe "WITH a non backlogs tracked work_package as it's parent" do
      let(:parent) { bug }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end
  end

  describe "WITH a task" do
    subject { task }

    describe "WITHOUT a parent work_package (would then be an impediment)" do
      it_should_behave_like "fixed version without restriction"
    end

    describe "WITH a task as it's parent" do
      before(:each) do
        story.save!
        task2.parent_id = story.id # a task needs a parent
        task2.save!
        story.reload
        task.parent_id = task2.id
        task.save!
        task2.reload
      end

      let(:parent) { story } # it's actually the grandparent but it makes no difference for the test

      it_should_behave_like "fixed version beeing inherited from the parent"
    end

    describe "WITH a story as it's parent" do
      let(:parent) { story }

      it_should_behave_like "fixed version beeing inherited from the parent"
    end

    describe "WITH a non backlogs tracked work_package as it's parent" do
      let(:parent) { bug }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end
  end

  describe "WITH a non backlogs work_package" do
    subject { bug }

    describe "WITHOUT a parent work_package" do
      it_should_behave_like "fixed version without restriction"
    end

    describe "WITH a task as it's parent" do
      let(:parent) { task2 }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end

    describe "WITH a story as it's parent" do
      let(:parent) { story }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end

    describe "WITH a non backlogs tracked work_package as it's parent" do
      let(:parent) { bug2 }

      it_should_behave_like "fixed version not beeing inherited from the parent"
    end
  end
end
