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
    post path, parameters.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  subject(:response) { last_response }
  let(:errors) {
    parse_json(subject.body)['_embedded']['errors']
  }

  describe 'empty request body' do
    it 'should return 422' do
      expect(response.status).to eq(422)
    end

    it 'has 5 validation errors' do
      expect(errors.count).to eq(5)
      expect(errors.collect{ |el| el['_embedded']['details']['attribute']})
        .to contain_exactly('password', 'login', 'firstname', 'lastname', 'email')

      expect(subject.body)
        .to be_json_eql('urn:openproject-org:api:v3:errors:MultipleErrors'.to_json)
        .at_path('errorIdentifier')
    end
  end

  describe 'creating a user' do
    let(:password) { 'admin!admin!' }
    let(:parameters) {
      {
        status: status,
        login: 'myusername',
        firstName: 'Foo',
        lastName: 'Bar',
        email: 'foobar@example.org',
        password: password,
      }
    }

    describe 'active status' do
      let(:status) { 'active' }
      it 'returns the represented user' do
        expect(subject.body).not_to have_json_path("_embedded/errors")
        expect(subject.body).to have_json_type(Object).at_path('_links')
        expect(subject.body)
          .to be_json_eql('User'.to_json)
          .at_path('_type')
      end

      it 'creates the user' do
        user = User.find_by!(login: 'myusername')
        expect(user.firstname).to eq('Foo')
        expect(user.lastname).to eq('Bar')
        expect(user.mail).to eq('foobar@example.org')
      end

      context 'empty password' do
        let(:password) { '' }

        it 'marks the password missing and too short' do
          expect(errors.count).to eq(2)
          expect(errors.collect{ |el| el['_embedded']['details']['attribute']})
            .to match_array %w(password password)
        end
      end
    end
  end
end
