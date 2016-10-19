#-- encoding: UTF-8
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

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Users::UsersAPI do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.users }
  let(:user) { FactoryGirl.build(:admin) }
  let(:parameters) { {} }

  before do
    login_as(user)
  end

  def send_request
    post path, parameters.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  subject(:response) { last_response }
  let(:errors) { parse_json(subject.body)['_embedded']['errors'] }

  shared_context 'represents the created user' do |expected_attributes|
    it 'returns the represented user' do
      send_request

      expect(subject.body).to have_json_type(Object).at_path('_links')
      expect(subject.body)
        .to be_json_eql('User'.to_json)
        .at_path('_type')

      parameters.merge!(expected_attributes) if expected_attributes

      user = User.find_by!(login: parameters.fetch(:login, parameters[:email]))
      expect(user.firstname).to eq(parameters[:firstName])
      expect(user.lastname).to eq(parameters[:lastName])
      expect(user.mail).to eq(parameters[:email])
    end
  end

  describe 'empty request body' do
    it 'returns an erroneous response' do
      send_request

      expect(response.status).to eq(422)

      expect(errors.count).to eq(5)
      expect(errors.collect { |el| el['_embedded']['details']['attribute'] })
        .to contain_exactly('password', 'login', 'firstname', 'lastname', 'email')

      expect(subject.body)
        .to be_json_eql('urn:openproject-org:api:v3:errors:MultipleErrors'.to_json)
        .at_path('errorIdentifier')
    end
  end

  describe 'active status' do
    let(:status) { 'active' }
    let(:password) { 'admin!admin!' }
    let(:parameters) {
      {
        status: status,
        login: 'myusername',
        firstName: 'Foo',
        lastName: 'Bar',
        email: 'foobar@example.org',
        password: password
      }
    }

    it 'returns the represented user' do
      send_request

      expect(subject.body).not_to have_json_path("_embedded/errors")
      expect(subject.body).to have_json_type(Object).at_path('_links')
      expect(subject.body)
        .to be_json_eql('User'.to_json)
        .at_path('_type')
    end

    it_behaves_like 'represents the created user'

    context 'empty password' do
      let(:password) { '' }

      it 'marks the password missing and too short' do
        send_request

        expect(errors.count).to eq(2)
        expect(errors.collect { |el| el['_embedded']['details']['attribute'] })
          .to match_array %w(password password)
      end
    end
  end

  describe 'invited status' do
    let(:status) { 'invited' }
    let(:invitation_request) {
      {
        status: status,
        email: 'foo@example.org'
      }
    }

    describe 'invitation successful' do
      before do
        expect(OpenProject::Notifications).to receive(:send) do |event, _|
          expect(event).to eq 'user_invited'
        end
      end

      context 'only mail set' do
        let(:parameters) { invitation_request }

        it_behaves_like 'represents the created user',
                        firstName: 'foo',
                        lastName: '@example.org'

        it 'sets the other attributes' do
          send_request

          user = User.find_by!(login: 'foo@example.org')
          expect(user.firstname).to eq('foo')
          expect(user.lastname).to eq('@example.org')
          expect(user.mail).to eq('foo@example.org')
        end
      end

      context 'mail and name set' do
        let(:parameters) { invitation_request.merge(firstName: 'First', lastName: 'Last') }

        it_behaves_like 'represents the created user'
      end
    end

    context 'missing email' do
      let(:parameters) { { status: status } }

      it 'marks the mail as missing' do
        send_request

        expect(subject.body)
          .to be_json_eql('urn:openproject-org:api:v3:errors:PropertyConstraintViolation'.to_json)
          .at_path('errorIdentifier')
        expect(subject.body)
          .to be_json_eql('email'.to_json)
          .at_path('_embedded/details/attribute')
      end
    end
  end

  describe 'invalid status' do
    let(:parameters) { { status: 'blablu' } }

    it 'returns an erroneous response' do
      send_request

      expect(response.status).to eq(422)

      expect(errors).not_to be_empty
      expect(subject.body)
        .to be_json_eql('urn:openproject-org:api:v3:errors:MultipleErrors'.to_json)
        .at_path('errorIdentifier')

      expect(errors.collect { |el| el['message'] })
        .to include 'Status is not a valid status for new users.'
    end
  end
end
