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

describe AccountController do
  after do
    User.delete_all
    User.current = nil
  end

  describe "Login for user with forced password change" do
    let(:user) do
      FactoryGirl.create(:admin, force_password_change: true)
      User.any_instance.stub(:change_password_allowed?).and_return(false)
    end

    before do
      User.current = user
    end

    describe "User who is not allowed to change password can't login" do
      before do
        admin = User.find_by_admin(true)

        post "change_password", :username => admin.login,
          :password => 'adminADMIN!',
          :new_password => 'adminADMIN!New',
          :new_password_confirmation => 'adminADMIN!New'
      end

      it "should redirect to the login page" do
        expect(response).to redirect_to '/login'
      end
    end

    describe "User who is not allowed to change password, is not redirected to the login page" do
      before do
        admin = User.find_by_admin(true)
        post "login", {:username => admin.login, :password => 'adminADMIN!'}
      end

      it "should redirect ot the login page" do
        expect(response).to redirect_to '/login'
      end
    end
  end

  context "GET #register" do
    context "with self registration on" do
      before do
        Setting.stub!(:self_registration).and_return("3")
        get :register
      end

      it "is successful" do
        should respond_with :success
        should render_template :register
        expect(assigns[:user]).not_to be_nil
      end
    end

    context "with self registration off" do
      before do
        Setting.stub!(:self_registration).and_return("0")
        Setting.stub!(:self_registration?).and_return(false)
        get :register
      end

      it "redirects to home" do
        should redirect_to('/') { home_url }
      end
    end
  end

  # See integration/account_test.rb for the full test
  context "POST #register" do
    context "with self registration on automatic" do
      before do
        Setting.stub!(:self_registration).and_return("3")
        post :register, :user => {
          :login => 'register',
          :password => 'adminADMIN!',
          :password_confirmation => 'adminADMIN!',
          :firstname => 'John',
          :lastname => 'Doe',
          :mail => 'register@example.com'
        }
      end

      it "redirects to my account page"  do
        should respond_with :redirect
        expect(assigns[:user]).not_to be_nil
        should redirect_to('/my/account')
        expect(User.last(:conditions => {:login => 'register'})).not_to be_nil
      end

      it 'set the user status to active' do
        user = User.last(:conditions => {:login => 'register'})
        expect(user).not_to be_nil
        expect(user.status).to eq(User::STATUSES[:active])
      end
    end

    context "with self registration off" do
      before do
        Setting.stub!(:self_registration).and_return("0")
        Setting.stub!(:self_registration?).and_return(false)
        post :register, :user => {
          :login => 'register',
          :password => 'adminADMIN!',
          :password_confirmation => 'adminADMIN!',
          :firstname => 'John',
          :lastname => 'Doe',
          :mail => 'register@example.com'
        }
      end

      it "redirects to home" do
        should redirect_to('/') { home_url }
      end
    end
  end
end
