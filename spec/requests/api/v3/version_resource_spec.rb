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

describe 'API v3 Version resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    user = FactoryGirl.create(:user,
                              member_in_project: project,
                              member_through_role: role)

    allow(User).to receive(:current).and_return user

    user
  end
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:other_project) { FactoryGirl.create(:project, is_public: false) }
  let(:version_in_project) { FactoryGirl.build(:version, project: project) }
  let(:version_in_other_project) do
    FactoryGirl.build(:version, project: other_project,
                                sharing: 'system')
  end

  subject(:response) { last_response }

  describe '#get (:id)' do
    let(:get_path) { api_v3_paths.version version_in_project.id }

    shared_examples_for 'successful response' do
      it 'responds with 200' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the version' do
        expect(last_response.body).to be_json_eql('Version'.to_json).at_path('_type')
        expect(last_response.body).to be_json_eql(expected_version.id.to_json).at_path('id')
      end
    end

    context 'logged in user with permissions' do
      before do
        version_in_project.save!
        current_user

        get get_path
      end

      it_should_behave_like 'successful response' do
        let(:expected_version) { version_in_project }
      end
    end

    context 'logged in user with permission on project a version is shared with' do
      let(:get_path) { api_v3_paths.version version_in_other_project.id }

      before do
        version_in_other_project.save!
        current_user

        get get_path
      end

      it_should_behave_like 'successful response' do
        let(:expected_version) { version_in_other_project }
      end
    end

    context 'logged in user without permission' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      before(:each) do
        version_in_project.save!
        current_user

        get get_path
      end

      it_behaves_like 'unauthorized access'
    end
  end

  describe '#get /versions' do
    let(:get_path) { api_v3_paths.versions }
    let(:response) { last_response }
    let(:versions) { [version_in_project] }

    before do
      versions.map(&:save!)
      current_user

      get get_path
    end

    it 'succeeds' do
      expect(last_response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Version'

    it 'is the version the user has permission in' do
      expect(response.body)
        .to be_json_eql(api_v3_paths.version(version_in_project.id).to_json)
        .at_path('_embedded/elements/0/_links/self/href')
    end

    context 'filtering for project by sharing' do
      let(:shared_version_in_project) do
        FactoryGirl.build(:version, project: project, sharing: 'system')
      end
      let(:versions) { [version_in_project, shared_version_in_project] }

      let(:filter_query) do
        [{ sharing: { operator: '=', values: ['system'] } }]
      end

      let(:get_path) do
        "#{api_v3_paths.versions}?filters=#{CGI.escape(JSON.dump(filter_query))}"
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Version'

      it 'returns the shared version' do
        expect(response.body)
          .to be_json_eql(api_v3_paths.version(shared_version_in_project.id).to_json)
          .at_path('_embedded/elements/0/_links/self/href')
      end
    end
  end
end
