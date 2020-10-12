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

describe ::API::V3::Memberships::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:permissions) { [:manage_members] }

  let(:path) { api_v3_paths.create_membership_form }
  let(:parameters) { {} }

  before do
    login_as(user)

    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/memberships/form' do
    it 'returns 200 OK' do
      expect(response.status).to eq(200)
    end

    it 'returns a form' do
      expect(response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end

    it 'does not create a member' do
      # 1 as the current user already has a membership
      expect(Member.count)
        .to eql 1
    end

    context 'with empty parameters' do
      it 'has 4 validation errors' do
        # There are 4 validation errors instead of 3 with two duplicating each other
        expect(subject.body).to have_json_size(4).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on principal' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/principal')
      end

      it 'has a validation error on project' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/project')
      end

      it 'has a validation error on roles' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/roles')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'with all parameters' do
      let!(:int_cf) { FactoryBot.create(:int_version_custom_field) }
      let!(:list_cf) { FactoryBot.create(:list_version_custom_field) }
      let(:parameters) do
        {
          principal: {
            href: api_v3_paths.user(other_user.id)
          },
          project: {
            href: api_v3_paths.project(project.id)
          },
          roles: [
            {
              href: api_v3_paths.role(role.id)
            }
          ]
        }
      end

      it 'has 0 validation errors' do
        expect(subject.body).to have_json_size(0).at_path('_embedded/validationErrors')
      end

      it 'has the values prefilled in the payload' do
        body = subject.body

        expect(body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_embedded/payload/_links/project/href')

        expect(body)
          .to be_json_eql(api_v3_paths.user(other_user.id).to_json)
          .at_path('_embedded/payload/_links/principal/href')

        expect(subject.body)
          .to have_json_size(1)
          .at_path('_embedded/payload/_links/roles')

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.role(role.id).to_json)
          .at_path('_embedded/payload/_links/roles/0/href')
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.memberships.to_json)
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
