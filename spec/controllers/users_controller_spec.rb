require 'spec_helper'

describe UsersController do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  describe :routes do
    describe "users" do
      it { params_from(:get, "/users/1/deletion_info").should == { :controller => 'users',
                                                                   :action => 'deletion_info',
                                                                   :id => "1" } }
      it { params_from(:delete, "/users/1").should == { :controller => 'users',
                                                        :action => 'destroy',
                                                        :id => "1" } }
    end

    describe "my" do
      before do
        User.stub!(:current).and_return(user)
      end

      it { params_from(:get, "/my/deletion_info").should == { :controller => 'users',
                                                              :action => 'deletion_info' } }
    end
  end

  describe "GET deletion_info" do

    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to true" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(user)
        Setting.stub!(:users_deletable_by_self?).and_return(true)

        get :deletion_info, params
      end

      it { response.should be_success }
      it { assigns(:user).should == user }
      it { response.should render_template("deletion_info") }
    end

    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to false" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(user)
        Setting.stub!(:users_deletable_by_self?).and_return(false)

        get :deletion_info, params
      end

      it { response.response_code.should == 404 }
    end

    describe "WHEN the current user is the anonymous user" do
      let(:params) { { "id" => User.anonymous.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(User.anonymous)

        get :deletion_info, params
      end

      it { response.should redirect_to({ :controller => 'account',
                                         :action => 'login',
                                         :back_url => @controller.url_for({ :controller => 'users',
                                                                            :action => 'deletion_info' }) }) }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to true" do
      let(:admin) { FactoryGirl.create(:admin) }
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(admin)
        Setting.stub!(:users_deletable_by_admins?).and_return(true)

        get :deletion_info, params
      end

      it { response.should be_success }
      it { assigns(:user).should == user }
      it { response.should render_template("deletion_info") }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to false" do
      let(:admin) { FactoryGirl.create(:admin) }
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(admin)
        Setting.stub!(:users_deletable_by_admins?).and_return(false)

        get :deletion_info, params
      end

      it { response.response_code.should == 404 }
    end
  end

  describe "POST destroy" do
    describe "WHEN the current user is the requested one
              WHEN the setting users_deletable_by_self is set to true" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.instance_eval{ flash.stub!(:sweep) }
        @controller.stub!(:find_current_user).and_return(user)
        Setting.stub!(:users_deletable_by_self?).and_return(true)

        post :destroy, params
      end

      it { response.should redirect_to({ :controller => 'account', :action => 'login' }) }
      it { flash[:notice].should == I18n.t('account.deleted') }
    end

    describe "WHEN the current user is the requested one
              WHEN the setting users_deletable_by_self is set to false" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.instance_eval{ flash.stub!(:sweep) }
        @controller.stub!(:find_current_user).and_return(user)
        Setting.stub!(:users_deletable_by_self?).and_return(false)

        post :destroy, params
      end

      it { response.response_code.should == 404 }
    end

    describe "WHEN the current user is the anonymous user
              EVEN when the setting login_required is set to false" do
      let(:params) { { "id" => User.anonymous.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(User.anonymous)
        Setting.stub!(:login_required?).and_return(false)

        post :destroy, params
      end

      # redirecting post is not possible for now
      it { response.response_code.should == 403 }
    end

    describe "WHEN the current user is the admin
              WHEN the setting users_deletable_by_admins is set to true" do
      let(:admin) { FactoryGirl.create(:admin) }
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.instance_eval{ flash.stub!(:sweep) }
        @controller.stub!(:find_current_user).and_return(admin)
        Setting.stub!(:users_deletable_by_admins?).and_return(true)

        post :destroy, params
      end

      it { response.should redirect_to({ :controller => 'users', :action => 'index' }) }
      it { flash[:notice].should == I18n.t('account.deleted') }
    end

    describe "WHEN the current user is the admin
              WHEN the setting users_deletable_by_admins is set to false" do
      let(:admin) { FactoryGirl.create(:admin) }
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.instance_eval{ flash.stub!(:sweep) }
        @controller.stub!(:find_current_user).and_return(admin)
        Setting.stub!(:users_deletable_by_admins).and_return(false)

        post :destroy, params
      end

      it { response.response_code.should == 404 }
    end
  end
end
