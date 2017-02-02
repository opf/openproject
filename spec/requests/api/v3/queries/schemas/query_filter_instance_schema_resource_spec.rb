#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Query Filter Schema resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project) }
  let(:visible_child) do
    child = FactoryGirl.create(:project, parent: project)
    child.add_member! user, role

    child
  end
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  before do
    allow(User)
      .to receive(:current)
      .and_return(user)
  end

  let(:global_path) { api_v3_paths.query_filter_instance_schemas }
  let(:project_path) { api_v3_paths.query_project_filter_instance_schemas(project.id) }

  subject do
    last_response
  end

  def instance_in_collection(response, name)
    collection_hash = ::JSON.parse(response)

    collection_hash['_embedded']['elements'].any? do |instance_hash|
      href = instance_hash['_links']['self']['href']

      href == api_v3_paths.query_filter_instance_schema(name)
    end
  end

  before do
    get path
  end

  describe '#get queries/filter_instance_schemas' do
    [:global,
     :project].each do |current_path|
      context current_path do
        let(:path) { send "#{current_path}_path".to_sym }

        it 'succeeds' do
          expect(subject.status)
            .to eql(200)
        end

        it 'returns a collection of schemas' do
          expect(subject.body)
            .to be_json_eql('Collection'.to_json)
            .at_path('_type')
          expect(subject.body)
            .to be_json_eql(path.to_json)
            .at_path('_links/self/href')

          expected_type = "QueryFilterInstanceSchema"

          expect(subject.body)
            .to be_json_eql(expected_type.to_json)
            .at_path('_embedded/elements/0/_type')
        end

        context 'user not allowed' do
          let(:permissions) { [] }

          it_behaves_like 'unauthorized access'
        end
      end
    end

    context 'global' do
      let(:path) { global_path }

      before do
        visible_child
        get path
      end

      it 'includes only global specific filter' do
        expect(instance_in_collection(subject.body, 'project'))
          .to be_truthy

        expect(instance_in_collection(subject.body, 'subprojectId'))
          .to be_falsey
      end
    end

    context 'project' do
      let(:path) { project_path }

      before do
        visible_child
        get path
      end

      it 'includes only project specific filter' do
        expect(instance_in_collection(subject.body, 'project'))
          .to be_falsey

        expect(instance_in_collection(subject.body, 'subprojectId'))
          .to be_truthy
      end
    end
  end

  describe '#get queries/filter_instance_schemas/:id' do
    let(:filter_name) { 'assignee' }
    let(:path) { api_v3_paths.query_filter_instance_schema(filter_name) }

    it 'succeeds' do
      expect(subject.status)
        .to eql(200)
    end

    it 'returns the instance schema' do
      expect(subject.body)
        .to be_json_eql(path.to_json)
        .at_path('_links/self/href')
    end

    context 'user not allowed' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end

    context 'not found' do
      let(:filter_name) { 'bogus' }

      it_behaves_like 'not found'
    end
  end
end
