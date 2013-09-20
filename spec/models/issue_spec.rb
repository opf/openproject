require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  describe 'behavior for #3200' do
    before(:each) do
      @example = WorkPackage.new
    end

    it do
      @example.move_to_project_without_transaction(nil).should be_false
    end

    it do
      lambda { @example.move_to_project_without_transaction(nil) }.should_not raise_error(NoMethodError)
    end
  end

  describe 'validations' do
    let(:work_package) do
      FactoryGirl.build(:work_package)
    end

    describe 'story points' do
      before(:each) do
        work_package.project.enabled_module_names += ["backlogs"]
      end

      it 'allows empty values' do
        work_package.story_points.should be_nil
        work_package.should be_valid
      end

      it 'allows values greater than or equal to 0' do
        work_package.story_points = '0'
        work_package.should be_valid

        work_package.story_points = '1'
        work_package.should be_valid
      end

      it 'allows values less than 10.000' do
        work_package.story_points = '9999'
        work_package.should be_valid
      end

      it 'disallows negative values' do
        work_package.story_points = '-1'
        work_package.should_not be_valid
      end

      it 'disallows greater or equal than 10.000' do
        work_package.story_points = '10000'
        work_package.should_not be_valid

        work_package.story_points = '10001'
        work_package.should_not be_valid
      end

      it 'disallows string values, that are not numbers' do
        work_package.story_points = 'abc'
        work_package.should_not be_valid
      end

      it 'disallows non-integers' do
        work_package.story_points = '1.3'
        work_package.should_not be_valid
      end
    end


    describe 'remaining hours' do
      it 'allows empty values' do
        work_package.remaining_hours.should be_nil
        work_package.should be_valid
      end

      it 'allows values greater than or equal to 0' do
        work_package.remaining_hours = '0'
        work_package.should be_valid

        work_package.remaining_hours = '1'
        work_package.should be_valid
      end

      it 'disallows negative values' do
        work_package.remaining_hours = '-1'
        work_package.should_not be_valid
      end

      it 'disallows string values, that are not numbers' do
        work_package.remaining_hours = 'abc'
        work_package.should_not be_valid
      end

      it 'allows non-integers' do
        work_package.remaining_hours = '1.3'
        work_package.should be_valid
      end
    end
  end

  describe 'definition of done' do
    before(:each) do
      @status_resolved = FactoryGirl.build(:issue_status, :name => "Resolved", :is_default => false)
      @status_open = FactoryGirl.build(:issue_status, :name => "Open", :is_default => true)
      @project = FactoryGirl.build(:project)
      @project.issue_statuses = [@status_resolved]

      @work_package = FactoryGirl.build(:work_package, :project => @project,
                                        :status  => @status_open,
                                        :type => FactoryGirl.build(:type_feature))
    end

    it 'should not be done when having the initial status "open"' do
      @work_package.done?.should be_false
    end

    it 'should be done when having the status "resolved"' do
      @work_package.status = @status_resolved
      @work_package.done?.should be_true
    end

   it 'should not be done when removing done status from "resolved"' do
     @work_package.status = @status_resolved
     @project.issue_statuses = Array.new
     @work_package.done?.should be_false
    end
  end

  describe "backlogs_enabled?" do
    let(:project) { FactoryGirl.build(:project) }
    let(:work_package) { FactoryGirl.build(:work_package) }

    it "should be false without a project" do
      work_package.project = nil
      work_package.should_not be_backlogs_enabled
    end

    it "should be true with a project having the backlogs module" do
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      work_package.project = project

      work_package.should be_backlogs_enabled
    end

    it "should be false with a project not having the backlogs module" do
      work_package.project = project
      work_package.project.enabled_module_names = nil

      work_package.should_not be_backlogs_enabled
    end
  end
end
