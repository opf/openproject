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

    context 'with global basic auth configured' do
      let(:username) { 'root' }
      let(:password) { 'toor' }

      before do
        authentication = {
          'global_basic_auth' => {
            'user'     => username,
            'password' => password
          }
        }
        OpenProject::Configuration['authentication'] = authentication
      end

      context 'with login required' do
        before do
          Setting.login_required = 1
        end

        it_behaves_like 'it is basic auth protected'
      end
    end
  end
end
