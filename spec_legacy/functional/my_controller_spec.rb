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
require 'my_controller'

describe MyController, type: :controller do
  fixtures :all

  before do
    session[:user_id] = 2
  end

  it 'should page' do
    get :page
    assert_response :success
    assert_template 'page'
  end

  it 'should my account should not show non editable custom fields' do
    UserCustomField.find(4).update_attribute :editable, false

    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)
  end

  it 'should page layout' do
    get :page_layout
    assert_response :success
    assert_template 'page_layout'
  end

  it 'should add block' do
    post :add_block, params: { block: 'issuesreportedbyme' }, xhr: true
    assert_response :success
    assert User.find(2).pref[:my_page_layout]['top'].include?('issuesreportedbyme')
  end

  it 'should remove block' do
    post :remove_block, params: { block: 'issuesassignedtome' }, xhr: true
    assert_response :success
    assert !User.find(2).pref[:my_page_layout].values.flatten.include?('issuesassignedtome')
  end

  it 'should order blocks' do
    post :order_blocks,
         params: { target: 'left', 'target_ordered_children' => ['documents', 'calendar', 'latestnews'] },
         xhr: true
    assert_response :success
    assert_equal ['documents', 'calendar', 'latestnews'], User.find(2).pref[:my_page_layout]['left']
  end
end
