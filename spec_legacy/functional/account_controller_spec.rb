#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative '../legacy_spec_helper'
require 'account_controller'

describe AccountController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should login with wrong password' do
    post :login, params: { username: 'admin', password: 'bad' }
    assert_response :success
    assert_template 'login'
    assert_select 'div.flash.error.icon.icon-error', /Invalid user or password/
  end

  it 'should login' do
    get :login
    assert_template 'login'
  end

  it 'should login should reset session' do
    expect(@controller).to receive(:reset_session).once

    post :login, params: { username: 'jsmith', password: 'jsmith' }
    assert_response 302
  end

  it 'should login with logged account' do
    session[:user_id] = 2
    get :login
    assert_redirected_to home_url
  end

  it 'should logout' do
    session[:user_id] = 2
    get :logout
    assert_redirected_to '/'
    assert_nil session[:user_id]
  end

  it 'should logout should reset session' do
    expect(@controller).to receive(:reset_session).once

    session[:user_id] = 2
    get :logout
    assert_response 302
  end
end
