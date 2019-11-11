#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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
require 'rack/test'

describe 'BCF 2.1 projects resource', type: :request do
  include Rack::Test::Methods

  let(:member_user) do
    FactoryBot.create(:user,
                      member_in_project: project)
  end
  let(:non_member_user) do
    FactoryBot.create(:user)
  end

  let(:project) { FactoryBot.create(:project) }
  subject(:response) { last_response }

  describe 'GET /api/bcf/2.1/projects/:project_id' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}" }
    let(:current_user) { member_user }

    before do
      login_as(current_user)
      get path
    end

    it 'responds 200 OK' do
      expect(subject.status)
        .to eql 200
    end

    it 'returns the project' do
      expected = {
        project_id: project.id,
        name: project.name
      }

      expect(subject.body)
        .to be_json_eql(expected.to_json)
    end

    it 'is has a json content type header' do
      expect(subject.headers['Content-Type'])
        .to eql 'application/json; charset=utf-8'
    end

    context 'lacking permissions' do
      let(:current_user) { non_member_user }

      it 'responds 404 NOT FOUND' do
        expect(subject.status)
          .to eql 404
      end

      it 'states a NOT FOUND message' do
        expected = {
          message: 'The requested resource could not be found.'
        }

        expect(subject.body)
          .to be_json_eql(expected.to_json)
      end

      it 'is has a json content type header' do
        expect(subject.headers['Content-Type'])
          .to eql 'application/json; charset=utf-8'
      end
    end
  end
end
