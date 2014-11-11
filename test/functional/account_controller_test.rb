#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require File.expand_path('../../test_helper', __FILE__)
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

describe AccountController do
  render_views

  before do
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  it 'login_with_wrong_password' do
    post :login, :username => 'admin', :password => 'bad'
    assert_response :success
    assert_template 'login'
    assert_select "div.flash.error.icon.icon-error", /Invalid user or password/
  end

  it 'login' do
    get :login
    assert_template 'login'
  end

  it 'login_should_reset_session' do
    @controller.should_receive(:reset_session).once

    post :login, :username => 'jsmith', :password => 'jsmith'
    assert_response 302
  end

  it 'login_with_logged_account' do
    @request.session[:user_id] = 2
    get :login
    assert_redirected_to home_url
  end

  it 'logout' do
    @request.session[:user_id] = 2
    get :logout
    assert_redirected_to '/'
    assert_nil @request.session[:user_id]
  end

  it 'logout_should_reset_session' do
    @controller.should_receive(:reset_session).once

    @request.session[:user_id] = 2
    get :logout
    assert_response 302
  end
end
