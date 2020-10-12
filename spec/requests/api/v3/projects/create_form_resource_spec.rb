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

describe ::API::V3::Projects::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user).tap do |u|
      u.global_roles << global_role
    end
  end
  let(:global_role) do
    FactoryBot.create(:global_role, permissions: permissions)
  end
  let(:text_custom_field) do
    FactoryBot.create(:text_project_custom_field)
  end
  let(:list_custom_field) do
    FactoryBot.create(:list_project_custom_field)
  end
  let(:permissions) { [:add_project] }
  let(:path) { api_v3_paths.create_project_form }
  let(:params) do
    {
    }
  end

  before do
    login_as(current_user)

    post path, params.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/projects/form' do
    it 'returns 200 OK' do
      expect(response.status).to eq(200)
    end

    it 'returns a form' do
      expect(response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end

    it 'does not create a project' do
      expect(Project.count)
        .to eql 0
    end

    context 'with empty parameters' do
      it 'has 2 validation errors' do
        expect(subject.body).to have_json_size(2).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on name' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/name')
      end

      it 'has a validation error on identifier' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/identifier')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'with all parameters' do
      let(:params) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          "customField#{text_custom_field.id}": {
            "raw": "CF text"
          },
          status: 'on track',
          statusExplanation: { raw: "A magic dwells in each beginning." },
          "_links": {
            "customField#{list_custom_field.id}": {
              "href": api_v3_paths.custom_option(list_custom_field.custom_options.first.id)
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
          .to be_json_eql('new_project_identifier'.to_json)
          .at_path('_embedded/payload/identifier')

        expect(body)
          .to be_json_eql('Project name'.to_json)
          .at_path('_embedded/payload/name')

        expect(body)
          .to be_json_eql('CF text'.to_json)
          .at_path("_embedded/payload/customField#{text_custom_field.id}/raw")

        expect(body)
          .to be_json_eql(api_v3_paths.custom_option(list_custom_field.custom_options.first.id).to_json)
          .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/href")

        expect(body)
          .to be_json_eql('on track'.to_json)
          .at_path('_embedded/payload/status')

        expect(body)
          .to be_json_eql(
            {
              "format": "markdown",
              "html": "<p>A magic dwells in each beginning.</p>",
              "raw": "A magic dwells in each beginning."
            }.to_json
          ).at_path("_embedded/payload/statusExplanation")
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.projects.to_json)
          .at_path('_links/commit/href')
      end
    end

    context 'with faulty status parameters' do
      let(:params) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          status: "bogus"
        }
      end

      it 'has 1 validation errors' do
        expect(subject.body).to have_json_size(1).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on status' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/status')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
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
