#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'API v3 Project resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:project) do
    FactoryBot.create(:project, is_public: false)
  end
  let(:other_project) do
    FactoryBot.create(:project, is_public: false)
  end
  let(:role) { FactoryBot.create(:role) }
  let(:custom_field) do
    FactoryBot.create(:text_project_custom_field)
  end
  let(:custom_value) do
    CustomValue.create(custom_field: custom_field,
                       value: '1234',
                       customized: project)
  end

  before do
    login_as(current_user)
  end

  describe '#get /projects/:id' do
    let(:get_path) { api_v3_paths.project project.id }
    let!(:parent_project) do
      FactoryBot.create(:project, is_public: false).tap do |p|
        project.parent = p
        project.save!
      end
    end
    let!(:parent_memberships) do
      FactoryBot.create(:member,
                        user: current_user,
                        project: parent_project,
                        roles: [FactoryBot.create(:role, permissions: [])])
    end

    subject(:response) do
      get get_path

      last_response
    end

    context 'logged in user' do
      it 'responds with 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'responds with the correct project' do
        expect(subject.body).to include_json('Project'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(project.identifier.to_json).at_path('identifier')
      end

      it 'links to the parent project' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.project(parent_project.id).to_json)
          .at_path('_links/parent/href')
      end

      it 'includes custom fields' do
        custom_value

        expect(subject.body)
          .to be_json_eql(custom_value.value.to_json)
          .at_path("customField#{custom_field.id}/raw")
      end

      context 'requesting nonexistent project' do
        let(:get_path) { api_v3_paths.project 9999 }

        before do
          response
        end

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'Project' }
        end
      end

      context 'requesting project without sufficient permissions' do
        let(:get_path) { api_v3_paths.project other_project.id }

        before do
          response
        end

        it_behaves_like 'not found' do
          let(:id) { another_project.id.to_s }
          let(:type) { 'Project' }
        end
      end

      context 'not being allowed to see the parent project' do
        let!(:parent_memberships) do
        end

        it 'has no path to the parent' do
          expect(subject.body)
            .to be_json_eql(nil.to_json)
            .at_path('_links/parent/href')
        end
      end
    end

    context 'not logged in user' do
      let(:current_user) { FactoryBot.create(:anonymous) }

      before do
        get get_path
      end

      it_behaves_like 'not found'
    end
  end

  describe '#get /projects' do
    let(:get_path) { api_v3_paths.projects }
    let(:response) { last_response }
    let(:projects) { [project, other_project] }

    before do
      projects

      get get_path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Project'

    context 'filtering for project by ancestor' do
      let(:projects) { [project, other_project, parent_project] }

      let(:parent_project) do
        parent_project = FactoryBot.create(:project, is_public: false)

        project.update_attribute(:parent_id, parent_project.id)

        parent_project.add_member! current_user, role

        parent_project
      end

      let(:filter_query) do
        [{ ancestor: { operator: '=', values: [parent_project.id.to_s] } }]
      end

      let(:get_path) do
        "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Project'

      it 'returns the child project' do
        expect(response.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_embedded/elements/0/_links/self/href')
      end
    end

    context 'filtering for principals (members)' do
      let(:other_project) do
        Role.non_member
        FactoryBot.create(:public_project)
      end
      let(:projects) { [project, other_project] }

      context 'if filtering for a value' do
        let(:filter_query) do
          [{ principal: { operator: '=', values: [current_user.id.to_s] } }]
        end

        let(:get_path) do
          "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
        end

        it 'returns the filtered for value' do
          expect(response.body)
            .to be_json_eql(project.id.to_json)
            .at_path('_embedded/elements/0/id')
        end
      end

      context 'if filtering for a negative value' do
        let(:filter_query) do
          [{ principal: { operator: '!', values: [current_user.id.to_s] } }]
        end

        let(:get_path) do
          "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
        end

        it 'returns the projects not matching the value' do
          expect(response.body)
            .to be_json_eql(other_project.id.to_json)
            .at_path('_embedded/elements/0/id')
        end
      end
    end
  end

  describe '#post /projects' do
    let(:current_user) do
      FactoryBot.create(:user).tap do |u|
        u.global_roles << global_role
      end
    end
    let(:global_role) do
      FactoryBot.create(:global_role, permissions: permissions)
    end
    let(:permissions) { [:add_project] }
    let(:path) { api_v3_paths.projects }
    let(:body) do
      {
        identifier: 'new_project_identifier',
        name: 'Project name'
      }.to_json
    end

    before do
      login_as current_user

      post path, body
    end

    it 'responds with 201 CREATED' do
      expect(last_response.status).to eq(201)
    end

    it 'creates a project' do
      expect(Project.count)
        .to eql(1)
    end

    it 'returns the created project' do
      expect(last_response.body)
        .to be_json_eql('Project'.to_json)
        .at_path('_type')
      expect(last_response.body)
        .to be_json_eql('Project name'.to_json)
        .at_path('name')
    end

    context 'with a custom field' do
      let(:body) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          "customField#{custom_field.id}": {
            "raw": "CF text"
          }
        }.to_json
      end

      it 'sets the cf value' do
        expect(last_response.body)
          .to be_json_eql("CF text".to_json)
          .at_path("customField#{custom_field.id}/raw")
      end
    end

    context 'without permission to create projects' do
      let(:permissions) { [] }

      it 'responds with 403' do
        expect(last_response.status).to eq(403)
      end

      it 'creates no project' do
        expect(Project.count)
          .to eql(0)
      end
    end

    context 'with faulty params' do
      let(:body) do
        {
          identifier: 'some_identifier'
        }.to_json
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'creates no project' do
        expect(Project.count)
          .to eql(0)
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end
    end
  end

  describe '#patch /projects/:id' do
    let(:current_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: permissions)
    end
    let(:permissions) { [:edit_project] }
    let(:path) { api_v3_paths.project(project.id) }
    let(:body) do
      {
        identifier: 'new_project_identifier',
        name: 'Project name'
      }
    end

    before do
      login_as current_user

      patch path, body.to_json
    end

    it 'responds with 200 OK' do
      expect(last_response.status).to eq(200)
    end

    it 'alters the project' do
      project.reload

      expect(project.name)
        .to eql(body[:name])

      expect(project.identifier)
        .to eql(body[:identifier])
    end

    it 'returns the updated project' do
      expect(last_response.body)
        .to be_json_eql('Project'.to_json)
        .at_path('_type')
      expect(last_response.body)
        .to be_json_eql(body[:name].to_json)
        .at_path('name')
    end

    context 'with a custom field' do
      let(:body) do
        {
          "customField#{custom_field.id}": {
            "raw": "CF text"
          }
        }
      end

      it 'responds with 200 OK' do
        expect(last_response.status).to eq(200)
      end

      it 'sets the cf value' do
        expect(project.reload.send("custom_field_#{custom_field.id}"))
          .to eql("CF text")
      end
    end

    context 'without permission to create projects' do
      let(:permissions) { [] }

      it 'responds with 403' do
        expect(last_response.status).to eq(403)
      end

      it 'does not change the project' do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql(attributes_before['name'])
      end
    end

    context 'with faulty params' do
      let(:body) do
        {
          name: nil
        }
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'does not change the project' do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql(attributes_before['name'])
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end
    end
  end
end
