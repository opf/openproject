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
    User.current = nil
  end

  describe "Login for user with forced password change" do
    let(:user) do
      User.any_instance.stub(:change_password_allowed?).and_return(false)
      FactoryGirl.create(:admin, :force_password_change => true)
    end

    before do
      User.current = user
    end

    describe "User who is not allowed to change password can't login" do
      before do
        admin = User.find{|u| u.admin}

        post "change_password", :username => admin.login,
                                :password => 'adminADMIN!',
                                :new_password => 'adminADMIN!New',
                                :new_password_confirmation => 'adminADMIN!New'
      end

      it "should redirect to the login page" do
        response.should redirect_to '/login'
      end
    end

    describe "User who is not allowed to change password, is not redirected to the login page" do
      before do
        admin = User.find{|u| u.admin}

        post "login", {:username => admin.login, :password => 'adminADMIN!'}
      end

      it "should redirect ot the login page" do
        response.should redirect_to '/login'
      end
    end
  end
end
