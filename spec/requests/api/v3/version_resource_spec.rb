#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Version resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: []) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:versions) { FactoryGirl.create_list(:version, 4, project: project) }
  let(:other_versions) { FactoryGirl.create_list(:version, 2) }

  subject(:response) { last_response }

  describe '#get (index)' do
    let(:get_path) { "/api/v3/projects/#{project.id}/versions" }

    context 'logged in user' do
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!

        versions
        other_versions

        get get_path
      end

      it_behaves_like 'API V3 collection response', 4, 4, 'Version'
    end
  end

  describe '#get (:id)' do
    let(:version_in_project) { FactoryGirl.build(:version, project: project) }

    let(:get_path) { "/api/v3/versions/#{version_in_project.id}" }

    let(:expected_response) do
      {
        '_type' => 'Version'
      }
    end

    context 'logged in user with permissions' do
      let(:current_user) do
        user = FactoryGirl.create(:user,
                                  member_in_project: project,
                                  member_through_role: role)

        allow(User).to receive(:current).and_return user

        user
      end

      before do
        version_in_project.save!

        get get_path
      end

      it 'responds with 200' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the work package' do
        expected = {
          _type: 'Version',
          name: version_in_project.name
        }.to_json

        expect(last_response.body).to be_json_eql(expected)
      end
    end
  end
end
