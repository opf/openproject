require 'spec_helper'

describe MeetingsController do
  before(:each) do
    @p = mock_model(Project)
    @controller.stub!(:authorize)
    @controller.stub!(:check_if_login_required)
  end

  describe "GET" do
    describe "index" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @ms = [mock_model(Meeting), mock_model(Meeting), mock_model(Meeting)]
        @ms.stub!(:from_tomorrow).and_return(@ms)
        @p.stub!(:meetings).and_return(@ms)
        @ms.stub!(:find_time_sorted).and_return(@ms)
      end
      describe "html" do
        before(:each) do
          get "index", :project_id => @p.id
        end
        it {response.should be_success}
        it {assigns(:meetings_by_start_year_month_date).should eql @ms}
      end
    end

    describe "show" do
      before(:each) do
        @m = mock_model(Meeting)
        Meeting.stub!(:find).and_return(@m)
        @m.stub!(:project).and_return(@p)
        @m.stub!(:agenda).stub!(:present?).and_return(false)
      end
      describe "html" do
        before(:each) do
          get "show", :id => @m.id
        end
        it {response.should be_success}
      end
    end

    describe "new" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @m = mock_model(Meeting)
        @m.stub!(:project=)
        @m.stub!(:author=)
        Meeting.stub!(:new).and_return(@m)
      end
      describe "html" do
        before(:each) do
          get "new", :project_id => @p.id
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end

    describe "edit" do
      before(:each) do
        @m = mock_model(Meeting)
        Meeting.stub!(:find).and_return(@m)
        @m.stub(:project).and_return(@p)
      end
      describe "html" do
        before(:each) do
          get "edit", :id => @m.id
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end
  end
end
