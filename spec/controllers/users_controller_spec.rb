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
end
