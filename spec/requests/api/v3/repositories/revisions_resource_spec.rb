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

describe 'API v3 Revisions resource', type: :request do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  let(:revision) {
    FactoryBot.create(:changeset,
                       repository: repository,
                       comments: 'Some commit message',
                       committer: 'foo bar <foo@example.org>'
    )
  }
  let(:repository) {
    FactoryBot.create(:repository_subversion, project: project)
  }
  let(:project) {
    FactoryBot.create(:project, identifier: 'test_project', public: false)
  }
  let(:role) {
    FactoryBot.create(:role,
                       permissions: [:view_changesets])
  }
  let(:current_user) {
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  }

  let(:unauthorized_user) { FactoryBot.create(:user) }

  describe '#get' do
    let(:get_path) { api_v3_paths.revision revision.id }

    context 'when acting as a user with permission to view revisions' do
      before(:each) do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(last_response.status).to eq(200)
      end

      describe 'response body' do
        subject(:response) { last_response.body }

        it 'should respond with revision in HAL+JSON format' do
          is_expected.to be_json_eql(revision.id.to_json).at_path('id')
        end
      end

      context 'requesting nonexistent revision' do
        let(:get_path) { api_v3_paths.revision 909090 }

        it_behaves_like 'not found'
      end
    end

    context 'when acting as an user without permission to view work package' do
      before(:each) do
        allow(User).to receive(:current).and_return unauthorized_user
        get get_path
      end

      it_behaves_like 'not found'
    end
  end
end
