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

describe 'API v3 Project available parents resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let!(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_with_permissions: permissions).tap do |u|
      u.global_roles << FactoryBot.create(:global_role, permissions: global_permissions)
    end
  end
  let!(:project_with_add_suproject_permission) do
    FactoryBot.create(:project).tap do |p|
      FactoryBot.create(:member,
                        user: current_user,
                        project: p,
                        roles: [FactoryBot.create(:role, permissions: [:add_subprojects])])
    end
  end
  let!(:child_project_with_add_suproject_permission) do
    FactoryBot.create(:project, parent: project).tap do |p|
      FactoryBot.create(:member,
                        user: current_user,
                        project: p,
                        roles: [FactoryBot.create(:role, permissions: [:add_subprojects])])
    end
  end
  let!(:project_without_add_suproject_permission) do
    FactoryBot.create(:project).tap do |p|
      FactoryBot.create(:member,
                        user: current_user,
                        project: p,
                        roles: [FactoryBot.create(:role, permissions: [])])
    end
  end
  let!(:project) do
    FactoryBot.create(:project, public: false)
  end
  let(:permissions) { %i[edit_project add_subprojects] }
  let(:global_permissions) { %i[add_project] }
  let(:path) { api_v3_paths.path_for(:projects_available_parents, sort_by: [%i[id asc]]) }

  describe 'GET /api/v3/projects/available_parent_projects' do
    before do
      login_as current_user
    end

    subject(:response) do
      get path

      last_response
    end

    context 'without a project candidate' do
      it 'returns 200 OK' do
        expect(subject.status)
          .to eql 200
      end

      it 'returns projects for which the user has the add_subprojects permission' do
        expect(subject.body)
          .to have_json_size(3)
          .at_path('_embedded/elements')

        expect(subject.body)
          .to be_json_eql(project.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(project_with_add_suproject_permission.id.to_json)
          .at_path('_embedded/elements/1/id')

        expect(subject.body)
          .to be_json_eql(child_project_with_add_suproject_permission.id.to_json)
          .at_path('_embedded/elements/2/id')
      end
    end

    context 'with a project candidate' do
      let(:path) { api_v3_paths.projects_available_parents + "?of=#{project.id}" }

      it 'returns 200 OK' do
        expect(subject.status)
          .to eql 200
      end

      it 'returns projects for which the user has the add_subprojects permission but' +
         ' excludes the queried for project and it`s descendants' do
        expect(subject.body)
          .to have_json_size(1)
                .at_path('_embedded/elements')

        expect(subject.body)
          .to be_json_eql(project_with_add_suproject_permission.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'if lacking edit and add permission' do
      let(:permissions) { %i[add_subprojects] }
      let(:global_permissions) { %i[] }

      it 'returns 403' do
        expect(subject.status)
          .to eql 403
      end
    end

    context 'if having only edit permission' do
      let(:permissions) { %i[edit_project add_subprojects] }
      let(:global_permissions) { %i[] }

      it 'returns 200' do
        expect(subject.status)
          .to eql 200
      end
    end

    context 'if having only add permission' do
      let(:permissions) { %i[add_subprojects] }
      let(:global_permissions) { %i[add_project] }

      it 'returns 200' do
        expect(subject.status)
          .to eql 200
      end
    end
  end
end
