#-- encoding: UTF-8
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
require File.expand_path('../../test_helper', __FILE__)

class AccountTest < ActionDispatch::IntegrationTest
  fixtures :all

  def test_autologin
    user = User.find(1)
    Setting.autologin = "7"
    Token.delete_all

    # User logs in with 'autologin' checked
    post '/login', :username => user.login, :password => 'adminADMIN!', :autologin => 1
    assert_redirected_to '/my/page'
    token = Token.find :first
    assert_not_nil token
    assert_equal user, token.user
    assert_equal 'autologin', token.action
    assert_equal user.id, session[:user_id]
    assert_equal token.value, cookies[Redmine::Configuration['autologin_cookie_name']]

    # Session is cleared
    reset!
    User.current = nil
    # Clears user's last login timestamp
    user.update_attribute :last_login_on, nil
    assert_nil user.reload.last_login_on

    # User comes back with his autologin cookie
    cookies[Redmine::Configuration['autologin_cookie_name']] = token.value
    get '/my/page'
    assert_response :success
    assert_template 'my/page'
    assert_equal user.id, session[:user_id]
    assert_not_nil user.reload.last_login_on
    assert user.last_login_on.utc > 20.second.ago.utc
  end

  should_eventually "login after losing password should redirect back to home" do
    visit "/login"
    assert_response :success

    click_link "Lost password"
    assert_response :success

    # Lost password form
    fill_in "mail", :with => "admin@somenet.foo"
    click_button "Submit"

    assert_response :success # back to login page
    assert_equal "/login", current_path

    fill_in "Login:", :with => 'admin'
    fill_in "Password:", :with => 'test'
    click_button "login"

    assert_response :success
    assert_equal "/", current_path

  end
end
