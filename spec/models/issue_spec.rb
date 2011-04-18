require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do
  describe 'behavior for #3200' do
    before(:each) do
      @example = Issue.new
      @example.stub(:move_to_project_without_transaction_without_autolink).and_return(false)
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

      it 'allows values greater than 0' do
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

      it 'disallows 0 and negative values' do
        issue.story_points = '0'
        issue.should_not be_valid

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
end
