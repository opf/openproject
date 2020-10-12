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
require 'rack/test'

describe "POST /api/v3/grids/form", type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:current_user) do
    FactoryBot.create(:user)
  end

  let(:path) { api_v3_paths.create_grid_form }
  let(:params) { {} }
  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe '#post' do
    before do
      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns 200 OK' do
      expect(subject.status)
        .to eql 200
    end

    it 'is of type form' do
      expect(subject.body)
        .to be_json_eql("Form".to_json)
        .at_path('_type')
    end

    it 'contains default data in the payload' do
      expected = {
        "rowCount": 4,
        "columnCount": 5,
        "widgets": [],
        "options": {},
        "_links": {
          "attachments": []
        }
      }

      expect(subject.body)
        .to be_json_eql(expected.to_json)
        .at_path('_embedded/payload')
    end

    it 'has a validation error on scope' do
      expect(subject.body)
        .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
        .at_path('_embedded/validationErrors/scope/message')
    end

    it 'does not have a commit link' do
      expect(subject.body)
        .not_to have_json_path('_links/commit')
    end
  end
end
