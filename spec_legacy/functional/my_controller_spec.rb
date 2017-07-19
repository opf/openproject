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

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'page'
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

  context 'POST to reset_rss_key' do
    context 'with an existing rss_token' do
      before do
        @previous_token_value = User.find(2).rss_key # Will generate one if it's missing
        post :reset_rss_key
      end

      it 'should destroy the existing token' do
        refute_equal @previous_token_value, User.find(2).rss_key
      end

      it 'should create a new token' do
        assert User.find(2).rss_token
      end

      it { is_expected.to set_flash.to /reset/ }
      it { is_expected.to redirect_to '/my/access_token' }
    end

    context 'with no rss_token' do
      before do
        assert_nil User.find(2).rss_token
        post :reset_rss_key
      end

      it 'should create a new token' do
        assert User.find(2).rss_token
      end

      it { is_expected.to set_flash.to /reset/ }
      it { is_expected.to redirect_to '/my/access_token' }
    end
  end

  context 'POST to reset_api_key' do
    context 'with an existing api_token' do
      before do
        @previous_token_value = User.find(2).api_key # Will generate one if it's missing
        post :reset_api_key
      end

      it 'should destroy the existing token' do
        refute_equal @previous_token_value, User.find(2).api_key
      end

      it 'should create a new token' do
        assert User.find(2).api_token
      end

      it { is_expected.to set_flash.to /reset/ }
      it { is_expected.to redirect_to '/my/access_token' }
    end

    context 'with no api_token' do
      before do
        assert_nil User.find(2).api_token
        post :reset_api_key
      end

      it 'should create a new token' do
        assert User.find(2).api_token
      end

      it { is_expected.to set_flash.to /reset/ }
      it { is_expected.to redirect_to '/my/access_token' }
    end
  end
end
