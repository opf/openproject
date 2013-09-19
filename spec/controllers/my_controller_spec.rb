#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe MyController, :type => :controller do
  describe 'password change' do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      User.stub(:current).and_return(user)
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
