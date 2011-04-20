require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  before(:each) do
    @controller.stub!(:require_admin).and_return(true)
    @controller.stub!(:check_if_login_required)
    @controller.stub!(:set_localization)
    @global_roles = [mock_model(GlobalRole), mock_model(GlobalRole)]
    GlobalRole.stub!(:all).and_return(@global_roles)
    User.stub!(:find).with("1").and_return(mock_model User)
    
    disable_log_requesting_user
  end

  describe "get" do
    before :each do
      @params = {"id" => "1"}
    end

    describe :edit do
      before :each do

      end

      describe "RESULT" do
        before :each do

        end

        describe "html" do
          before :each do
            get "edit", @params
          end

          it { response.should be_success }
          it { assigns(:global_roles).should eql @global_roles }
          it { response.should render_template "users/edit"}
        end
      end

    end

  end
end