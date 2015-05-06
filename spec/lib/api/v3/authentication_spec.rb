#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe API::V3, type: :request do
  describe 'basic auth' do
    let(:user) { FactoryGirl.create :user }
    let(:resource) { "/api/v3/users/#{user.id}"}

    def basic_auth(user, password)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials user, password
      {'HTTP_AUTHORIZATION' => credentials}
    end

    shared_examples 'it is basic auth protected' do
      context 'without credentials' do
        before do
          get resource
        end

        it 'should return 401 unauthorized' do
          expect(response.status).to eq 401
        end
      end

      context 'with invalid credentials' do
        before do
          get resource, {}, basic_auth(username, password.reverse)
        end

        it 'should return 401 unauthorized' do
          expect(response.status).to eq 401
        end
      end

      context 'with valid credentials' do
        before do
          get resource, {}, basic_auth(username, password)
        end

        it 'should return 200 OK' do
          expect(response.status).to eq 200
        end
      end
    end

    context 'with login required' do
      before do
        Setting.login_required = 1
      end

      context 'with global basic auth configured' do
        let(:username) { 'root' }
        let(:password) { 'toor' }

        before do
          authentication = {
            'global_basic_auth' => {
              'user'     => 'root',
              'password' => 'toor'
            }
          }
          OpenProject::Configuration['authentication'] = authentication
        end

        it_behaves_like 'it is basic auth protected'

        describe 'user basic auth' do
          let(:username) { 'hans' }
          let(:password) { 'bambidibam' }

          let!(:api_user) do
            FactoryGirl.create :user,
                               login: username,
                               password: password,
                               password_confirmation: password
          end

          # check that user basic auth is tried when global basic auth fails
          it_behaves_like 'it is basic auth protected'
        end
      end
    end

    context 'without login required' do
      before do
        Setting.login_required = 0
      end

      context 'with global and user basic auth enabled' do
        let(:username) { 'hancholo' }
        let(:password) { 'olooleol' }

        let!(:api_user) do
          FactoryGirl.create :user,
                             login: 'user_account',
                             password: 'user_password',
                             password_confirmation: 'user_password'
        end

        before do
          authentication = {
            'global_basic_auth' => {
              'user'     => 'global_account',
              'password' => 'global_password'
            }
          }
          OpenProject::Configuration['authentication'] = authentication
        end

        context 'without credentials' do
          before do
            get resource
          end

          it 'should return 200 OK' do
            expect(response.status).to eq 200
          end

          it 'should "login" the anonymous user' do
            expect(User.current).to be_anonymous
          end
        end

        context 'with invalid credentials' do
          before do
            get resource, {}, basic_auth(username, password)
          end

          it 'should return 401 unauthorized' do
            expect(response.status).to eq 401
          end
        end

        context 'with valid global credentials' do
          before do
            get resource, {}, basic_auth('global_account', 'global_password')
          end

          it 'should return 200 OK' do
            expect(response.status).to eq 200
          end

          it 'should login an admin system user' do
            expect(User.current.is_a?(SystemUser)).to eq true
            expect(User.current).to be_admin
          end
        end

        context 'with valid user credentials' do
          before do
            get resource, {}, basic_auth('user_account', 'user_password')
          end

          it 'should return 200 OK' do
            expect(response.status).to eq 200
          end

          it 'should login user' do
            expect(User.current).to eq api_user
          end
        end
      end
    end
  end
end
