require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do
  describe 'behavior for #3200' do
    before(:each) do
      @example = Issue.new
    end

    it do
      @example.move_to_project_without_transaction(nil).should be_false
    end

    it do
      lambda { @example.move_to_project_without_transaction(nil) }.should_not raise_error(NoMethodError)
    end
  end

  describe 'validations' do
    let(:issue) { Factory.build(:issue, :project => Factory.build(:project),
                                        :status  => Factory.build(:issue_status),
                                        :tracker => Factory.build(:tracker_feature)) }

    describe 'story points' do
      it 'allows empty values' do
        issue.story_points.should be_nil
        issue.should be_valid
      end

      it 'allows values greater than or equal to 0' do
        issue.story_points = '0'
        issue.should be_valid

        issue.story_points = '1'
        issue.should be_valid
      end

      it 'allows values less than 10.000' do
        issue.story_points = '9999'
        issue.should be_valid
      end

      it 'disallows negative values' do
        issue.story_points = '-1'
        issue.should_not be_valid
      end

      it 'disallows greater or equal than 10.000' do
        issue.story_points = '10000'
        issue.should_not be_valid

        issue.story_points = '10001'
        issue.should_not be_valid
      end

      it 'disallows string values, that are not numbers' do
        issue.story_points = 'abc'
        issue.should_not be_valid
      end

      it 'disallows non-integers' do
        issue.story_points = '1.3'
        issue.should_not be_valid
      end
    end
  end

  describe 'definition of done' do
    before(:each) do
      @status_resolved ||= Factory.create(:issue_status, :name => "Resolved", :is_default => false)
      @status_open ||= Factory.create(:issue_status, :name => "Open", :is_default => true)
      @project = Factory.build(:project)
      @project.issue_statuses = [@status_resolved]

      @issue = Factory.build(:issue, :project => @project,
                                        :status  => @status_open,
                                        :tracker => Factory.build(:tracker_feature))
    end

    it 'should not be done when having the initial status "open"' do
      @issue.done?.should be_false
    end

    it 'should be done when having the status "resolved"' do
      @issue.status = @status_resolved
      @issue.done?.should be_true
    end

   it 'should not be done when removing done status from "resolved"' do
     @issue.status = @status_resolved
     @project.issue_statuses = Array.new
     @issue.done?.should be_false
    end
  end

  describe "backlogs_enabled?" do
    let(:project) { Factory.build(:project) }
    let(:issue) { Factory.build(:issue) }

    it "should be false without a project" do
      issue.should_not be_backlogs_enabled
    end

    it "should be true with a project having the backlogs module" do
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      issue.project = project

      issue.should be_backlogs_enabled
    end

    it "should be false with a project not having the backlogs module" do
      issue.project = project
      issue.project.enabled_module_names = nil

      issue.should_not be_backlogs_enabled
    end
  end
end
