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

require_relative '../../legacy_spec_helper'

describe 'ApiTest: DisabledRestApiTest', type: :request do
  fixtures :all

  before do
    Setting.rest_api_enabled = '0'
    Setting.login_required = '1'
  end

  after do
    Setting.rest_api_enabled = '1'
    Setting.login_required = '0'
  end

  context 'get /api/v2/projects with the API disabled' do
    context 'in :xml format' do
      context 'with a valid api token' do
        before do
          @user = FactoryGirl.create(:user)
          @token = FactoryGirl.create(:token, user: @user, action: 'api')
          get "/api/v2/projects.xml?key=#{@token.value}"
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/xml' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end

      context 'with a valid HTTP authentication' do
        before do
          @user = FactoryGirl.create(:user, password: 'adminADMIN!', password_confirmation: 'adminADMIN!')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'adminADMIN!')
          get '/api/v2/projects.xml', params: { authorization: @authorization }
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/xml' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end

      context 'with a valid HTTP authentication using the API token' do
        before do
          @user = FactoryGirl.create(:user)
          @token = FactoryGirl.create(:token, user: @user, action: 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'X')
          get '/api/v2/projects.xml', params: { authorization: @authorization }
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/xml' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end
    end

    context 'in :json format' do
      context 'with a valid api token' do
        before do
          @user = FactoryGirl.create(:user)
          @token = FactoryGirl.create(:token, user: @user, action: 'api')
          get "/api/v2/projects.json?key=#{@token.value}"
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/json' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end

      context 'with a valid HTTP authentication' do
        before do
          @user = FactoryGirl.create(:user, password: 'adminADMIN!', password_confirmation: 'adminADMIN!')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'adminADMIN!')
          get '/api/v2/projects.json', params: { authorization: @authorization }
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/json' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end

      context 'with a valid HTTP authentication using the API token' do
        before do
          @user = FactoryGirl.create(:user)
          @token = FactoryGirl.create(:token, user: @user, action: 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'DoesNotMatter')
          get '/api/v2/projects.json', params: { authorization: @authorization }
        end

        it { is_expected.to respond_with :unauthorized }
        it { should_respond_with_content_type 'application/json' }
        it 'should not login as the user' do
          assert_equal User.anonymous, User.current
        end
      end
    end
  end
end
