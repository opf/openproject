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

describe ::API::V3::Memberships::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:member) { FactoryBot.create(:member, project: project, roles: [role, another_role]) }
  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:other_role) { FactoryBot.create(:role) }
  let(:another_role) { FactoryBot.create(:role) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:permissions) { [:manage_members] }
  let(:project) { FactoryBot.create(:project) }
  let(:path) { api_v3_paths.membership_form(member.id) }
  let(:parameters) do
    {
      _links: {
        roles: [
          {
            href: api_v3_paths.role(role.id)
          },
          {
            href: api_v3_paths.role(other_role.id)
          }
        ]
      }
    }
  end

  before do
    login_as(user)
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe '#POST /api/v3/memberships/:id/form' do
    it 'returns 200 OK' do
      expect(response.status).to eq(200)
    end

    it 'returns a form' do
      expect(response.body)
        .to be_json_eql('Form'.to_json)
        .at_path('_type')
    end

    it 'does not update the member (no new roles)' do
      expect(member.roles.reload)
        .to match_array [role, another_role]
    end

    it 'contains the update roles in the payload' do
      expect(response.body)
        .to have_json_size(2)
        .at_path('_embedded/payload/_links/roles')

      expect(response.body)
        .to be_json_eql(api_v3_paths.role(role.id).to_json)
        .at_path('_embedded/payload/_links/roles/0/href')

      expect(response.body)
        .to be_json_eql(api_v3_paths.role(other_role.id).to_json)
        .at_path('_embedded/payload/_links/roles/1/href')
    end

    it 'does not contain the project in the payload' do
      expect(response.body)
        .not_to have_json_path('_embedded/payload/_links/project')
    end

    it 'does not contain the principal in the payload' do
      expect(response.body)
        .not_to have_json_path('_embedded/payload/_links/principal')
    end

    context 'with wanting to remove all roles' do
      let(:parameters) do
        {
          _links: {
            roles: []
          }
        }
      end

      it 'has 1 validation errors' do
        expect(subject.body).to have_json_size(1).at_path('_embedded/validationErrors')
      end

      it 'notes roles cannot be empty' do
        expect(subject.body)
          .to be_json_eql("Roles need to be assigned.".to_json)
          .at_path('_embedded/validationErrors/roles/message')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'with wanting to alter the project' do
      let(:other_project) do
        role = FactoryBot.create(:role, permissions: permissions)

        FactoryBot.create(:project,
                          members: [
                            FactoryBot.create(:member,
                                              roles: [role],
                                              user: user)
                          ])
      end
      let(:parameters) do
        {
          _links: {
            project: {
              href: api_v3_paths.project(other_project.id)
            }
          }
        }
      end

      it 'has 1 validation errors' do
        expect(subject.body).to have_json_size(1).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on project' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/project')
      end

      it 'notes project to not be writeable' do
        expect(subject.body)
          .to be_json_eql(false)
          .at_path('_embedded/schema/project/writable')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'with wanting to alter the principal' do
      let(:other_principal) do
        FactoryBot.create(:user)
      end
      let(:parameters) do
        {
          _links: {
            principal: {
              href: api_v3_paths.user(other_principal.id)
            }
          }
        }
      end

      it 'has 1 validation errors' do
        expect(subject.body).to have_json_size(1).at_path('_embedded/validationErrors')
      end

      it 'has a validation error on principal' do
        expect(subject.body).to have_json_path('_embedded/validationErrors/user')
      end

      it 'notes principal to not be writeable' do
        expect(subject.body)
          .to be_json_eql(false)
          .at_path('_embedded/schema/principal/writable')
      end

      it 'has no commit link' do
        expect(subject.body)
          .not_to have_json_path('_links/commit')
      end
    end

    context 'without the necessary edit permission' do
      let(:permissions) { [:view_members] }

      it 'returns 403 Not Authorized' do
        expect(response.status).to eq(403)
      end
    end

    context 'without the necessary view permission' do
      let(:permissions) { [] }

      it 'returns 404 Not Found' do
        expect(response.status).to eq(404)
      end
    end
  end
end
