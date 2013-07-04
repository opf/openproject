#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UsersController do
  before do
    User.delete_all
  end

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:anonymous) { FactoryGirl.create(:anonymous) }

  describe "GET deletion_info" do

    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to true" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        Setting.stub!(:users_deletable_by_self?).and_return(true)

        as_logged_in_user user do
          get :deletion_info, params
        end
      end

      it { response.should be_success }
      it { assigns(:user).should == user }
      it { response.should render_template("deletion_info") }
    end

    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to false" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        Setting.stub!(:users_deletable_by_self?).and_return(false)

        as_logged_in_user user do
          get :deletion_info, params
        end
      end

      it { response.response_code.should == 404 }
    end

    describe "WHEN the current user is the anonymous user" do
      let(:params) { { "id" => anonymous.id.to_s } }

      before do
        as_logged_in_user anonymous do
          get :deletion_info, params
        end
      end

      it { response.should redirect_to({ :controller => 'account',
                                         :action => 'login',
                                         :back_url => @controller.url_for({ :controller => 'users',
                                                                            :action => 'deletion_info' }) }) }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to true" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        Setting.stub!(:users_deletable_by_admins?).and_return(true)

        as_logged_in_user admin do
          get :deletion_info, params
        end
      end

      it { response.should be_success }
      it { assigns(:user).should == user }
      it { response.should render_template("deletion_info") }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to false" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        Setting.stub!(:users_deletable_by_admins?).and_return(false)

        as_logged_in_user admin do
          get :deletion_info, params
        end
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
        Setting.stub!(:users_deletable_by_self?).and_return(true)

        as_logged_in_user user do
          post :destroy, params
        end
      end

      it { response.should redirect_to({ :controller => 'account', :action => 'login' }) }
      it { flash[:notice].should == I18n.t('account.deleted') }
    end

    describe "WHEN the current user is the requested one
              WHEN the setting users_deletable_by_self is set to false" do
      let(:params) { { "id" => user.id.to_s } }

      before do
        @controller.instance_eval{ flash.stub!(:sweep) }
        Setting.stub!(:users_deletable_by_self?).and_return(false)

        as_logged_in_user user do
          post :destroy, params
        end
      end

      it { response.response_code.should == 404 }
    end

    describe "WHEN the current user is the anonymous user
              EVEN when the setting login_required is set to false" do
      let(:params) { { "id" => anonymous.id.to_s } }

      before do
        @controller.stub!(:find_current_user).and_return(anonymous)
        Setting.stub!(:login_required?).and_return(false)

        as_logged_in_user anonymous do
          post :destroy, params
        end
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
        Setting.stub!(:users_deletable_by_admins?).and_return(true)

        as_logged_in_user admin do
          post :destroy, params
        end
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
        Setting.stub!(:users_deletable_by_admins).and_return(false)

        as_logged_in_user admin do
          post :destroy, params
        end
      end

      it { response.response_code.should == 404 }
    end
  end

  describe "index" do
    describe "with session lifetime" do
      # TODO move this section to a proper place because we test a
      # before_filter from the application controller

      shared_examples_for "index action with disabled session lifetime or inactivity not exceeded" do
        it "doesn't logout the user and renders the index action" do
          User.current.should == admin
          response.should render_template "index"
        end
      end

      context "disabled" do
        before do
          Setting.stub!(:session_ttl_enabled?).and_return(false)
          @controller.send(:logged_user=, admin)
          get :index
        end

        it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
      end

      context "enabled " do
        before do
          Setting.stub!(:session_ttl_enabled?).and_return(true)
          Setting.stub!(:session_ttl).and_return("120")
          @controller.send(:logged_user=, admin)
        end

        context "before 120 min of inactivity" do
          before do
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context "after 120 min of inactivity" do
          before do
            session[:updated_at] = Time.now - 3.hours
            get :index
          end
          it "logs out the user and redirects with a warning that he has been locked out" do
            response.redirect_url.should == (signin_url + "?back_url=" + CGI::escape(@controller.url_for(:controller => "users", :action => "index")))
            User.current.should_not == admin
            flash[:warning].should == I18n.t(:notice_forced_logout, :ttl_time => Setting.session_ttl)
          end
        end

        context "with ttl = 0" do
          before do
            Setting.stub!(:session_ttl).and_return("0")
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context "with ttl < 0" do
          before do
            Setting.stub!(:session_ttl).and_return("-60")
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context "with ttl < 5 > 0" do
          before do
            Setting.stub!(:session_ttl).and_return("4")
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end
      end
    end
  end
end
