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

describe 'API v3 Grids resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:current_user) do
    FactoryBot.create(:user)
  end

  before do
    login_as(current_user)
  end

  subject(:response) { last_response }

  describe '#get INDEX' do
    let(:path) { api_v3_paths.grids }

    before do
      get path
    end

    it 'responds with 200 OK' do
      expect(subject.status).to eq(200)
    end
  end

  describe '#post' do
    let(:path) { api_v3_paths.grids }

    before do
      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    context 'without a page link' do
      let(:params) do
        {
          "rowCount": 5,
          "columnCount": 5,
          "widgets": [{
            "identifier": "work_packages_assigned",
            "startRow": 2,
            "endRow": 4,
            "startColumn": 2,
            "endColumn": 5
          }]
        }.with_indifferent_access
      end

      it 'responds with 422' do
        expect(subject.status).to eq(422)
      end

      it 'does not create a grid' do
        expect(Grids::Grid.count)
          .to eql(0)
      end

      it 'returns the errors' do
        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path('message')
      end
    end
  end
end
