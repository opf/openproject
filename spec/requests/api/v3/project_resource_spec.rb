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

describe 'API v3 Project resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:other_project) do
    FactoryGirl.create(:project, is_public: false)
  end
  let(:role) { FactoryGirl.create(:role) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get /projects/:id' do
    let(:get_path) { api_v3_paths.project project.id }
    subject(:response) { last_response }

    context 'logged in user' do
      before do
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct project' do
        expect(subject.body).to include_json('Project'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(project.identifier.to_json).at_path('identifier')
      end

      context 'requesting nonexistent project' do
        let(:get_path) { api_v3_paths.project 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'Project' }
        end
      end

      context 'requesting project without sufficient permissions' do
        let(:get_path) { api_v3_paths.project other_project.id }

        it_behaves_like 'not found' do
          let(:id) { another_project.id.to_s }
          let(:type) { 'Project' }
        end
      end
    end

    context 'not logged in user' do
      let(:current_user) { FactoryGirl.create(:anonymous) }

      before do
        get get_path
      end

      it_behaves_like 'not found'
    end
  end

  describe '#get /projects' do
    let(:get_path) { api_v3_paths.projects }
    let(:response) { last_response }

    before do
      other_project

      get get_path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Project'

    context 'filtering for project by ancestor' do
      let(:parent_project) do
        parent_project = FactoryGirl.create(:project, is_public: false)

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
  end
end
