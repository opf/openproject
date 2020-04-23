#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe API::V3, type: :request do
  describe 'basic auth' do
    let(:user)     { FactoryBot.create :user }
    let(:resource) { "/api/v3/projects" }

    let(:response_401) do
      {
        '_type'           => 'Error',
        'errorIdentifier' => 'urn:openproject-org:api:v3:errors:Unauthenticated',
        'message'         => expected_message
      }
    end

    let(:expected_message) { 'You need to be authenticated to access this resource.' }

    strategies = OpenProject::Authentication::Strategies::Warden

    def set_basic_auth_header(user, password)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials user, password
      header 'Authorization', credentials
    end

    shared_examples 'it is basic auth protected' do
      context 'when not allowed', with_config: { apiv3_enable_basic_auth: false } do
        context 'with valid credentials' do
          before do
            set_basic_auth_header(username, password)
            get resource
          end

          it 'should return 401 unauthorized' do
            expect(last_response.status).to eq 401
          end
        end
      end
      context 'when allowed', with_config: { apiv3_enable_basic_auth: true } do
        context 'without credentials' do
          before do
            get resource
          end

          it 'should return 401 unauthorized' do
            expect(last_response.status).to eq 401
          end

          it 'should return the correct JSON response' do
            expect(JSON.parse(last_response.body)).to eq response_401
          end

          it 'should return the WWW-Authenticate header' do
            expect(last_response.header['WWW-Authenticate'])
              .to include 'Basic realm="OpenProject API"'
          end
        end

        context 'with invalid credentials' do
          let(:expected_message) { 'You did not provide the correct credentials.' }

          before do
            set_basic_auth_header(username, password.reverse)
            get resource
          end

          it 'should return 401 unauthorized' do
            expect(last_response.status).to eq 401
          end

          it 'should return the correct JSON response' do
            expect(JSON.parse(last_response.body)).to eq response_401
          end

          it 'should return the correct content type header' do
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json; charset=utf-8'
          end

          it 'should return the WWW-Authenticate header' do
            expect(last_response.header['WWW-Authenticate'])
              .to include 'Basic realm="OpenProject API"'
          end
        end

        context 'with no credentials' do
          let(:expected_message) { 'You need to be authenticated to access this resource.' }

          before do
            post '/api/v3/time_entries/form'
          end

          it 'should return 401 unauthorized' do
            expect(last_response.status).to eq 401
          end

          it 'should return the correct JSON response' do
            expect(JSON.parse(last_response.body)).to eq response_401
          end

          it 'should return the correct content type header' do
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json; charset=utf-8'
          end


          it 'should return the WWW-Authenticate header' do
            expect(last_response.header['WWW-Authenticate'])
              .to include 'Basic realm="OpenProject API"'
          end
        end

        context 'with invalid credentials an X-Authentication-Scheme "Session"' do
          let(:expected_message) { 'You did not provide the correct credentials.' }

          before do
            set_basic_auth_header(username, password.reverse)
            header 'X-Authentication-Scheme', 'Session'
            get resource
          end

          it 'should return 401 unauthorized' do
            expect(last_response.status).to eq 401
          end

          it 'should return the correct JSON response' do
            expect(JSON.parse(last_response.body)).to eq response_401
          end

          it 'should return the correct content type header' do
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json; charset=utf-8'
          end

          it 'should return the WWW-Authenticate header' do
            expect(last_response.header['WWW-Authenticate'])
              .to include 'Session realm="OpenProject API"'
          end
        end

        context 'with valid credentials' do
          before do
            set_basic_auth_header(username, password)
            get resource
          end

          it 'should return 200 OK' do
            expect(last_response.status).to eq 200
          end
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
          strategies::GlobalBasicAuth.configure! user: 'root', password: 'toor'
        end

        it_behaves_like 'it is basic auth protected'

        describe 'user basic auth' do
          let(:api_key) { FactoryBot.create :api_token }

          let(:username) { 'apikey' }
          let(:password) { api_key.plain_value }

          # check that user basic auth is tried when global basic auth fails
          it_behaves_like 'it is basic auth protected'
        end
      end

      describe 'user basic auth' do
        let(:api_key) { FactoryBot.create :api_token }

        let(:username) { 'apikey' }
        let(:password) { api_key.plain_value }

        # check that user basic auth works on its own too
        it_behaves_like 'it is basic auth protected'
      end
    end

    context 'when enabled', with_config: { apiv3_enable_basic_auth: true } do
      context 'without login required' do
        before do
          allow(Setting).to receive(:login_required).and_return(false)
          allow(Setting).to receive(:login_required?).and_return(false)
        end

        context 'with global and user basic auth enabled' do
          let(:username) { 'hancholo' }
          let(:password) { 'olooleol' }

          let(:api_user) { FactoryBot.create :user, login: 'user_account' }
          let(:api_key)  { FactoryBot.create :api_token, user: api_user }

          before do
            config = { user: 'global_account', password: 'global_password' }
            strategies::GlobalBasicAuth.configure! config
          end

          context 'without credentials' do
            before do
              get resource
            end

            it 'should return 200 OK' do
              expect(last_response.status).to eq 200
            end

            it 'should "login" the anonymous user' do
              expect(User.current).to be_anonymous
            end
          end

          context 'with invalid credentials' do
            before do
              set_basic_auth_header(username, password)
              get resource
            end

            it 'should return 401 unauthorized' do
              expect(last_response.status).to eq 401
            end
          end

          context 'with valid global credentials' do
            before do
              set_basic_auth_header('global_account', 'global_password')
              get resource
            end

            it 'should return 200 OK' do
              expect(last_response.status).to eq 200
            end
          end

          context 'with valid user credentials' do
            before do
              set_basic_auth_header('apikey', api_key.plain_value)
              get resource
            end

            it 'should return 200 OK' do
              expect(last_response.status).to eq 200
            end
          end
        end
      end
    end
  end
end
