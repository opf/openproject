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
    
    describe "new without copy" do
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
    
    describe "new with copy" do
      before(:each) do
        Project.stub!(:find).with(@p.id.to_s).and_return(@p)
      end
      describe "with a valid meeting ID" do
        before(:each) do
          @mc = FactoryGirl.create(:meeting, "duration"=>1.5, "location"=>"Raum 4", "title"=>"dingens", "updated_at"=>Time.parse("Thu Feb 17 11:33:22 +0100 2011"), :start_time=>Time.parse("Fri Feb 18 14:36:25 +0100 2011"))
          @participants = [FactoryGirl.create(:meeting_participant, :meeting=>@mc)]
        end
        describe "html" do
          before(:each) do
            get "new", :project_id => @p.id, :copy_from_id => @mc.id
          end
          it {response.should be_success}
          it {assigns(:meeting).title.should eql "dingens"}
          it {assigns(:meeting).duration.should eql 1.5}
          it {assigns(:meeting).location.should eql "Raum 4"}
          it {assigns(:meeting).start_time.should eql (Date.tomorrow + 10.hours)}
          it {assigns(:meeting).participants.should eql @participants}
        end
      end
      describe "with an invalid meeting ID" do
        before(:each) do
          Meeting.delete_all
        end
        describe "html" do
          before(:each) do
            get "new", :project_id => @p.id, :copy_from_id => 42
          end
          it {response.should be_success}
          it {assigns(:meeting).should be_kind_of Meeting}
        end
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
