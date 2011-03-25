require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do

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