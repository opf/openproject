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

describe MyController, :type => :controller do
  describe 'password change' do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      User.stub!(:current).and_return(user)
    end

    describe :password do
      before do
        get :password
      end

      it 'should render the password template' do
        assert_template 'password'
        assert_response :success
      end
    end

    describe 'with wrong confirmation' do
      before do
        post :change_password, :password => 'adminADMIN!',
                               :new_password => 'adminADMIN!New',
                               :new_password_confirmation => 'adminADMIN!Other'
      end
      it 'should show an error message' do
        assert_response :success
        assert_template 'password'
        user.errors.keys.should == [:password]
        user.errors.values.flatten.join('').should include('confirmation')
      end
    end

    describe 'with wrong password' do
      render_views
      before do
        @current_password = user.current_password.id
        post :change_password, :password => 'wrongpassword',
                               :new_password => 'adminADMIN!New',
                               :new_password_confirmation => 'adminADMIN!New'
      end

      it 'should show an error message' do
        assert_response :success
        assert_template 'password'
        flash[:error].should == 'Wrong password'
      end

      it 'should not change the password' do
        user.current_password.id.should == @current_password
      end
    end

    describe 'with good password and good confirmation' do
      before do
        post :change_password, :password => 'adminADMIN!',
                               :new_password => 'adminADMIN!New',
                               :new_password_confirmation => 'adminADMIN!New'
      end

      it 'should redirect to the my account page' do
        expect(response).to redirect_to('/my/account')
      end

      it 'should allow the user to login with the new password' do
        assert User.try_to_login(user.login, 'adminADMIN!New')
      end
    end
  end
end
