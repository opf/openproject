require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MeetingsController do
  before(:each) do
    @p = mock_model(Project)
    @controller.stub!(:find_project)
    @controller.stub!(:authorize)
  end
  
  describe "GET" do
    describe "index" do
      before(:all) do
        @ms = [mock_model(Meeting), mock_model(Meeting), mock_model(Meeting)]
        @p.stub!(:meetings).and_return(@ms)
        @ms.stub!(:find).and_return(@ms)
      end
      describe "html" do
        before(:each) do
          get "index"
        end
        it {response.should be_success}
        it {assigns(:meetings).should eql @ms}
      end
    end
  end
end