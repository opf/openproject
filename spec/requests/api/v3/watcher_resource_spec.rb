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

describe 'API v3 Watcher resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:current_user) {
    FactoryGirl.create :user, member_in_project: project, member_through_role: role
  }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [] }
  let(:view_work_packages_role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:available_watcher) {
    FactoryGirl.create :user,
                       firstname: 'Something',
                       lastname: 'Strange',
                       member_in_project: project,
                       member_through_role: view_work_packages_role
  }

  let(:watching_user) {
    FactoryGirl.create :user,
                       member_in_project: project,
                       member_through_role: view_work_packages_role
  }
  let(:existing_watcher) {
    FactoryGirl.create(:watcher, watchable: work_package, user: watching_user)
  }

  subject(:response) { last_response }

  before do
    allow(User).to receive(:current).and_return current_user
    existing_watcher
  end

  describe '#get' do
    let(:get_path) { api_v3_paths.work_package_watchers work_package.id }
    let(:permissions) { [:view_work_packages, :view_work_package_watchers] }

    before do
      get get_path
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'User'

    context 'user not allowed to see watchers' do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like 'unauthorized access'
    end

    context 'user not allowed to see work package' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end
  end

  describe '#post' do
    let(:post_path) { api_v3_paths.work_package_watchers work_package.id }
    let(:post_body) {
      {
        user: { href: api_v3_paths.user(new_watcher.id) }
      }.to_json
    }
    let(:new_watcher) { available_watcher }

    let(:permissions) { [:add_work_package_watchers, :view_work_packages] }

    before do
      post post_path, post_body, 'CONTENT_TYPE' => 'application/json'
    end

    it 'should respond with 201' do
      expect(subject.status).to eq(201)
    end

    it 'should respond with newly added watcher' do
      expect(subject.body).to be_json_eql('User'.to_json).at_path('_type')
    end

    context 'when user is already watcher' do
      let(:new_watcher) { watching_user }

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct watcher' do
        expect(subject.body).to be_json_eql('User'.to_json).at_path('_type')
      end
    end

    context 'when the work package does not exist' do
      let(:post_path) { api_v3_paths.work_package_watchers 9999 }

      it_behaves_like 'not found' do
        let(:id) { 9999 }
        let(:type) { 'WorkPackage' }
      end
    end

    context 'when the user does not exist' do
      let(:post_body) {
        {
          user: { href: api_v3_paths.user(99999) }
        }.to_json
      }

      it_behaves_like 'not found'
    end

    context 'when the target user is not allowed to watch the work package' do
      let(:new_watcher) { FactoryGirl.create(:user) }

      it_behaves_like 'constraint violation' do
        let(:message) { 'User is invalid' }
      end
    end

    context 'unauthorized user' do
      context 'when the current user is trying to assign another user as watcher' do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like 'unauthorized access'
      end

      context 'when the current user tries to watch the work package her- or himself' do
        let(:current_user) { available_watcher }
        let(:new_watcher) { available_watcher }

        it 'should respond with 201' do
          expect(subject.status).to eq(201)
        end
      end
    end
  end

  describe '#delete' do
    let(:deleted_watcher) { watching_user }
    let(:delete_path) { api_v3_paths.watcher deleted_watcher.id, work_package.id }

    before do
      delete delete_path
    end

    context 'authorized user' do
      let(:permissions) { [:delete_work_package_watchers, :view_work_packages] }

      it 'should respond with 204' do
        expect(subject.status).to eq(204)
      end

      context 'when removing nonexistent user' do
        let(:delete_path) { api_v3_paths.watcher 9999, work_package.id }

        it_behaves_like 'not found'
      end

      context 'when removing user that is not watching' do
        let(:deleted_watcher) { available_watcher }

        it 'should respond with 204' do
          expect(subject.status).to eq(204)
        end
      end

      context 'when work package doesn\'t exist' do
        let(:delete_path) { api_v3_paths.watcher watching_user.id, 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'WorkPackage' }
        end
      end
    end

    context 'unauthorized user' do
      context 'when the current user tries to deassign another user from the watchers' do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like 'unauthorized access'
      end

      context 'when the current user tries to unwatch the work package her- or himself' do
        let(:current_user) { watching_user }
        let(:deleted_watcher) { watching_user }

        it 'should respond with 204' do
          expect(subject.status).to eq(204)
        end
      end
    end
  end

  describe '#available_watchers' do
    let(:permissions) { [:add_work_package_watchers, :view_work_packages] }
    let(:available_watchers_path) { api_v3_paths.available_watchers work_package.id }
    let(:returned_user_ids) {
      JSON.parse(subject.body)['_embedded']['elements'].map {|user| user['id'] }
    }

    before do
      available_watcher
      get available_watchers_path
    end

    it_behaves_like 'API V3 collection response', 2, 2, 'User'

    it 'includes a user eligible for watching' do
      expect(returned_user_ids).to match_array([available_watcher.id, current_user.id])
    end

    context 'when the user does not have the necessary permissions' do
      let(:permissions) { [:view_work_packages] }

      it 'responds with 403' do
        expect(subject.status).to eql(403)
      end
    end

    describe 'searching for a user' do
      let(:available_watchers_path) {
        path = api_v3_paths.available_watchers work_package.id
        filters = %([{ "name": { "operator": "~", "values": ["#{query}"] } }])
        "#{path}?filters=#{filters}"
      }

      context 'that does not exist' do
        let(:query) { 'asdfasdfasdfasdf' }
        it_behaves_like 'API V3 collection response', 0, 0, 'User'
      end

      context 'that does exist' do
        let(:query) { 'strange' }
        it_behaves_like 'API V3 collection response', 1, 1, 'User'
      end
    end
  end
end
