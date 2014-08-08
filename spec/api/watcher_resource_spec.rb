#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe 'API v3 Watcher resource', :type => :request do
  include Rack::Test::Methods

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:add_watchers_role) { FactoryGirl.create(:role, permissions: [:add_work_package_watchers]) }
  let(:delete_watchers_role) { FactoryGirl.create(:role, permissions: [:delete_work_package_watchers]) }
  let(:view_work_packages_role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:unauthorized_user) { FactoryGirl.create(:user) }
  let(:work_package) { FactoryGirl.create(:work_package, project_id: project.id) }
  let(:available_watcher) { FactoryGirl.create(:user, member_in_project: project, member_through_role: view_work_packages_role) }
  let(:watcher) { FactoryGirl.create :user,  member_in_project: project, member_through_role: view_work_packages_role }

  before do
    FactoryGirl.create(:watcher, watchable: work_package, user: watcher)
    allow(User).to receive(:current).and_return current_user
  end

  describe '#post' do
    subject(:response) { last_response }

    let(:post_path) { "/api/v3/work_packages/#{work_package.id}/watchers" }
    let(:new_watcher) { available_watcher }

    before do
      post post_path, user_id: new_watcher.id
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
        let(:post_path) { "/api/v3/work_packages/9999/watchers" }

        it 'should respond with 404' do
          expect(subject.status).to eq(404)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_found'.to_json).at_path('title')
        end
      end
    end

    context 'unauthorized user' do
      context 'when the current user is trying to assign another user as watcher' do
        let(:current_user) { unauthorized_user }

        it 'should respond with 403' do
          expect(subject.status).to eq(403)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authorized'.to_json).at_path('title')
        end
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
    let(:delete_path) { "/api/v3/work_packages/#{work_package.id}/watchers/#{existing_watcher.id}" }

    before { delete delete_path }

    context 'authorized user' do
      let(:current_user) { FactoryGirl.create :user,  member_in_project: project, member_through_role: delete_watchers_role }

      it 'should respond with 204' do
        expect(subject.status).to eq(204)
      end

      context 'when removing nonexistent watcher' do
        let(:delete_path) { "/api/v3/work_packages/#{work_package.id}/watchers/9999" }

        it 'should respond with 204' do
          expect(subject.status).to eq(204)
        end
      end

      context 'when work package doesn\'t exist' do
        let(:delete_path) { "/api/v3/work_packages/9999/watchers/#{watcher.id}" }

        it 'should respond with 404' do
          expect(subject.status).to eq(404)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_found'.to_json).at_path('title')
        end
      end
    end

    context 'unauthorized user' do
      context 'when the current user tries to deassign another user from the work package watchers' do
        let(:current_user) { unauthorized_user }

        it 'should respond with 403' do
          expect(subject.status).to eq(403)
        end

        it 'should respond with explanatory error message' do
          expect(subject.body).to include_json('not_authorized'.to_json).at_path('title')
        end
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
end
