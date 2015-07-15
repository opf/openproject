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
    let(:user)     { FactoryGirl.create :user }
    let(:resource) { "/api/v3/users/#{user.id}" }

    let(:response_401) do
      {
        '_embedded'       => {},
        '_type'           => 'Error',
        'errorIdentifier' => 'urn:openproject-org:api:v3:errors:Unauthenticated',
        'message'         => expected_message
      }
    end

    let(:expected_message) { 'You need to be authenticated to access this resource.' }

    Strategies = OpenProject::Authentication::Strategies::Warden

    def basic_auth(user, password)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials user, password
      { 'HTTP_AUTHORIZATION' => credentials }
    end

    shared_examples 'it is basic auth protected' do
      context 'without credentials' do
        before do
          get resource
        end

        it 'should return 401 unauthorized' do
          expect(response.status).to eq 401
        end

        it 'should return the correct JSON response' do
          expect(JSON.parse(response.body)).to eq response_401
        end

        it 'should return the WWW-Authenticate header' do
          expect(response.header['WWW-Authenticate'])
            .to include 'Basic realm="OpenProject API"'
        end
      end

      context 'with invalid credentials' do
        let(:expected_message) { 'You did not provide the correct credentials.' }

        before do
          get resource, {}, basic_auth(username, password.reverse)
        end

        it 'should return 401 unauthorized' do
          expect(response.status).to eq 401
        end

        it 'should return the correct JSON response' do
          expect(JSON.parse(response.body)).to eq response_401
        end

        it 'should return the correct content type header' do
          expect(response.headers['Content-Type']).to eq 'application/hal+json; charset=utf-8'
        end

        it 'should return the WWW-Authenticate header' do
          expect(response.header['WWW-Authenticate'])
            .to include 'Basic realm="OpenProject API"'
        end
      end

      context 'with invalid credentials an X-Authentication-Scheme "Session"' do
        let(:expected_message) { 'You did not provide the correct credentials.' }
        let(:headers) do
          auth = basic_auth(username, password.reverse)

          auth.merge('HTTP_X_AUTHENTICATION_SCHEME' => 'Session')
        end

        before do
          get resource, {}, headers
        end

        it 'should return 401 unauthorized' do
          expect(response.status).to eq 401
        end

        it 'should return the correct JSON response' do
          expect(JSON.parse(response.body)).to eq response_401
        end

        it 'should return the correct content type header' do
          expect(response.headers['Content-Type']).to eq 'application/hal+json; charset=utf-8'
        end

        it 'should return the WWW-Authenticate header' do
          expect(response.header['WWW-Authenticate'])
            .to include 'Session realm="OpenProject API"'
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
        allow(Setting).to receive(:login_required).and_return(true)
        allow(Setting).to receive(:login_required?).and_return(true)
      end

      context 'with global basic auth configured' do
        let(:username) { 'root' }
        let(:password) { 'toor' }

        before do
          Strategies::GlobalBasicAuth.configure! user: 'root', password: 'toor'
        end

        it_behaves_like 'it is basic auth protected'

        describe 'user basic auth' do
          let(:api_key) { FactoryGirl.create :api_key }

          let(:username) { 'apikey' }
          let(:password) { api_key.value }

          # check that user basic auth is tried when global basic auth fails
          it_behaves_like 'it is basic auth protected'
        end
      end

      describe 'user basic auth' do
        let(:api_key) { FactoryGirl.create :api_key }

        let(:username) { 'apikey' }
        let(:password) { api_key.value }

        # check that user basic auth works on its own too
        it_behaves_like 'it is basic auth protected'
      end
    end

    context 'without login required' do
      before do
        allow(Setting).to receive(:login_required).and_return(false)
        allow(Setting).to receive(:login_required?).and_return(false)
      end

      context 'with global and user basic auth enabled' do
        let(:username) { 'hancholo' }
        let(:password) { 'olooleol' }

        let(:api_user) { FactoryGirl.create :user, login: 'user_account' }
        let(:api_key)  { FactoryGirl.create :api_key, user: api_user }

        before do
          config = { user: 'global_account', password: 'global_password' }
          Strategies::GlobalBasicAuth.configure! config
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
            get resource, {}, basic_auth('apikey', api_key.value)
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
