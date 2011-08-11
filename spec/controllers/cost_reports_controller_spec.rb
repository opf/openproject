require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostReportsController do
  before(:each) do
    @user = Factory.build(:user)
    @user.stub(:roles_for_project)
    login_user @user
  end

  it "should respond with a 404 error" do
    get :show, :id => 1, :unit => -1 
    response.code.should eql("404")
  end
end
