require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MeetingsController do
  before(:each) do
    @p = mock_model(Project)
    @controller.stub!(:authorize)
  end
  
  describe "GET" do
    describe "index" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @ms = [mock_model(Meeting), mock_model(Meeting), mock_model(Meeting)]
        @p.stub!(:meetings).and_return(@ms)
        @ms.stub!(:find_time_sorted).and_return(@ms)
      end
      describe "html" do
        before(:each) do
          get "index"
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
          get "show"
        end
        it {response.should be_success}
      end
    end
    
    describe "new without copy" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @m = mock_model(Meeting)
        Meeting.stub!(:new).and_return(@m)
      end
      describe "html" do
        before(:each) do
          get "new"
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end
    
    describe "new with copy" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @m = mock_model(Meeting)
        Meeting.stub!(:new).and_return(@m)
      end
      #describe "with a valid meeting ID" do
      #  before(:each) do
      #    @mc = mock_model(Meeting)
      #    Meeting.stub!(:find).and_return(@mc)
      #    @mc.stub!(:attributes).and_return({"duration"=>1.5, "location"=>"Raum 4", "title"=>"dingens", "updated_at"=>Time.parse("Thu Feb 17 11:33:22 +0100 2011")})
      #    @mc.stub!(:start_time).and_return(Time.parse("Fri Feb 18 14:36:25 +0100 2011"))
      #    @mc.stub!(:participants).and_return([mock_model(MeetingParticipant), mock_model(MeetingParticipant), mock_model(MeetingParticipant)])
      #  end
      #  describe "html" do
      #    before(:each) do
      #      get "new", :copy_from_id => 1
      #    end
      #    it {pending; response.should be_success}
      #    it {pending; assigns(:meeting).should eql @m}
      #    it {pending} # TODO: testen ob das richtig kopiert wird
      #  end
      #end
      describe "with an invalid meeting ID" do
        before(:each) do
          Meeting.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
        end
        describe "html" do
          before(:each) do
            get "new", :copy_from_id => 1
          end
          it {response.should be_success}
          it {assigns(:meeting).should eql @m}
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
          get "edit"
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end
  end
end