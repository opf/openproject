#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Versions::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:permissions) { [:manage_versions] }

  let(:path) { api_v3_paths.create_version_form }
  let(:parameters) { {} }

  before do
    login_as(user)
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/versions/form' do
    it 'returns 200 OK' do
      expect(response.status).to eq(200)
    end

    it 'returns a form' do
      expect(response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end

    it 'does not create a version' do
      expect(Version.count)
        .to eql 0
    end

    context 'with empty parameters' do
      it 'has 2 validation errors' do
        expect(subject.body).to have_json_size(2).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on name' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/name')
      end

      it 'has a validation error on project' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/project')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'with all minimum parameters' do
      let(:parameters) do
        {
          _links: {
            definingProject: {
              href: api_v3_paths.project(project.id)
            }
          },
          name: 'lorem ipsum'
        }
      end

      it 'has 0 validation errors' do
        expect(subject.body).to have_json_size(0).at_path('_embedded/validationErrors')
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.versions.to_json)
          .at_path('_links/commit/href')
      end
    end

    context 'with all parameters' do
      let!(:int_cf) { FactoryBot.create(:int_version_custom_field) }
      let!(:list_cf) { FactoryBot.create(:list_version_custom_field) }
      let(:parameters) do
        {
          name: 'New version',
          description: {
            raw: 'A new description'
          },
          "customField#{int_cf.id}": 5,
          "startDate": "2018-01-01",
          "endDate": "2018-01-09",
          "status": "closed",
          "sharing": "descendants",
          _links: {
            definingProject: {
              href: api_v3_paths.project(project.id)
            },
            "customField#{list_cf.id}": {
              href: api_v3_paths.custom_option(list_cf.custom_options.first.id)
            }
          }
        }
      end

      it 'has 0 validation errors' do
        expect(subject.body).to have_json_size(0).at_path('_embedded/validationErrors')
      end

      it 'has the values prefilled in the payload' do
        body = subject.body

        expect(body)
          .to be_json_eql('New version'.to_json)
          .at_path('_embedded/payload/name')

        expect(last_response.body)
          .to be_json_eql('<p>A new description</p>'.to_json)
          .at_path('_embedded/payload/description/html')

        expect(last_response.body)
          .to be_json_eql('2018-01-01'.to_json)
          .at_path('_embedded/payload/startDate')

        expect(last_response.body)
          .to be_json_eql('2018-01-09'.to_json)
          .at_path('_embedded/payload/endDate')

        expect(last_response.body)
          .to be_json_eql('closed'.to_json)
          .at_path('_embedded/payload/status')

        expect(last_response.body)
          .to be_json_eql('descendants'.to_json)
          .at_path('_embedded/payload/sharing')

        expect(body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_embedded/payload/_links/definingProject/href')

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.custom_option(list_cf.custom_options.first.id).to_json)
          .at_path("_embedded/payload/_links/customField#{list_cf.id}/href")

        expect(last_response.body)
          .to be_json_eql(5.to_json)
          .at_path("_embedded/payload/customField#{int_cf.id}")
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.versions.to_json)
                .at_path('_links/commit/href')
      end
    end

    context 'without the necessary permission' do
      let(:permissions) { [] }

      it 'returns 403 Not Authorized' do
        expect(response.status).to eq(403)
      end
    end
  end
end
