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

describe 'API v3 Watcher resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:add_watchers_role) do
    FactoryGirl.create(:role, permissions: [:add_work_package_watchers, :view_work_packages])
  end
  let(:delete_watchers_role) do
    FactoryGirl.create(:role, permissions: [:delete_work_package_watchers, :view_work_packages])
  end
  let(:view_work_packages_role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:work_package) { FactoryGirl.create(:work_package, project_id: project.id) }
  let(:available_watcher) { FactoryGirl.create(:user, member_in_project: project, member_through_role: view_work_packages_role) }
  let(:watcher) { FactoryGirl.create :user,  member_in_project: project, member_through_role: view_work_packages_role }
  let(:existing_watcher) { FactoryGirl.create(:watcher, watchable: work_package, user: watcher) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#post' do
    subject(:response) { last_response }

    let(:post_path) { api_v3_paths.work_package_watchers work_package.id }
    let(:new_watcher) { available_watcher }

    before do
      existing_watcher

      post post_path, %{{"user_id": #{new_watcher.id}}},   'CONTENT_TYPE' => 'application/json'
    end

    context 'authorized user' do
      let(:current_user) { FactoryGirl.create :user,  member_in_project: project, member_through_role: add_watchers_role }

      it 'should respond with 201' do
        expect(subject.status).to eq(201)
      end

      it 'should respond with newly added watcher' do
        expect(subject.body).to be_json_eql('User'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(available_watcher.login.to_json).at_path('login')
      end

      context 'when user is already watcher' do
        let(:new_watcher) { watcher }

        it 'should respond with 200' do
          expect(subject.status).to eq(200)
        end

        it 'should respond with correct watcher' do
          expect(subject.body).to be_json_eql('User'.to_json).at_path('_type')
          expect(subject.body).to be_json_eql(watcher.login.to_json).at_path('login')
        end
      end

      context 'when work package doesn\'t exist' do
        let(:post_path) { api_v3_paths.work_package_watchers 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'WorkPackage' }
        end
      end
    end

    context 'unauthorized user' do
      context 'when the current user is trying to assign another user as watcher' do
        let(:current_user) do
          FactoryGirl.create(:user,
                             member_in_project: project,
                             member_through_role: view_work_packages_role)
        end

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
    subject(:response) { last_response }

    let(:existing_watcher) { watcher }
    let(:delete_path) { api_v3_paths.watcher existing_watcher.id, work_package.id }

    before do
      existing_watcher

      delete delete_path
    end

    context 'authorized user' do
      let(:current_user) { FactoryGirl.create :user,  member_in_project: project, member_through_role: delete_watchers_role }

      it 'should respond with 204' do
        expect(subject.status).to eq(204)
      end

      context 'when removing nonexistent watcher' do
        let(:delete_path) { api_v3_paths.watcher 9999, work_package.id }

        it 'should respond with 204' do
          expect(subject.status).to eq(204)
        end
      end

      context 'when work package doesn\'t exist' do
        let(:delete_path) { api_v3_paths.watcher watcher.id, 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'WorkPackage' }
        end
      end
    end

    context 'unauthorized user' do
      context 'when the current user tries to deassign another user from the work package watchers' do
        let(:view_watchers_role) do
          FactoryGirl.create(:role, permissions: [:view_work_package_watchers])
        end
        let(:current_user) do
          FactoryGirl.create :user,
                             member_in_project: project,
                             member_through_role: view_work_packages_role
        end

        it_behaves_like 'unauthorized access'
      end

      context 'when the current user tries to watch the work package her- or himself' do
        let(:current_user) { watcher }
        let(:new_watcher) { watcher }

        it 'should respond with 204' do
          expect(subject.status).to eq(204)
        end
      end
    end
  end

  describe '#available_watchers' do
    subject(:response) { last_response }
    let(:authorized_user) do
      FactoryGirl.create :user, member_in_project: project,
                                member_through_role: add_watchers_role
    end
    let(:current_user) { authorized_user }
    let(:available_watchers_path) { api_v3_paths.available_watchers work_package.id }

    before do
      available_watcher

      get available_watchers_path
    end

    it 'responds with 200' do
      expect(subject.status).to eql(200)
    end

    it 'has a total of 1' do
      expect(subject.body).to be_json_eql(2).at_path('total')
    end

    it 'has a count of 1' do
      expect(subject.body).to be_json_eql(2).at_path('count')
    end

    it 'has a user fit for watching embedded' do
      expect(subject.body).to have_json_size(2).at_path('_embedded/elements')
      expect(subject.body).to be_json_eql(available_watcher.id).at_path('_embedded/elements/1/id')
    end

    context 'when the user does not have the necessary permissions' do
      let(:current_user) do
        FactoryGirl.create(:user,
                           member_in_project: project,
                           member_through_role: view_work_packages_role)
      end

      it 'responds with 403' do
        expect(subject.status).to eql(403)
      end
    end
  end
end
