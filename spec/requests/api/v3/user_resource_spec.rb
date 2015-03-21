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

describe 'API v3 User resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.create(:user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:model) { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { ::API::V3::Users::UserRepresenter.new(model) }

  describe '#get' do
    subject(:response) { last_response }

    context 'logged in user' do
      let(:get_path) { api_v3_paths.user user.id }
      before do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct attachment' do
        expect(subject.body).to be_json_eql(user.name.to_json).at_path('name')
      end

      context 'requesting nonexistent user' do
        let(:get_path) { api_v3_paths.user 9999 }

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'User' }
        end
      end
    end

    it_behaves_like 'handling anonymous user', 'User', '/api/v3/users/%s' do
      let(:id) { user.id }
    end
  end

  describe '#delete' do
    let(:path) { api_v3_paths.user user.id }
    let(:admin_delete) { true }
    let(:self_delete) { true }

    before do
      allow(User).to receive(:current).and_return current_user

      allow(Setting).to receive(:users_deletable_by_admins?).and_return(admin_delete)
      allow(Setting).to receive(:users_deletable_by_self?).and_return(self_delete)

      delete path
    end

    subject(:response) { last_response }

    shared_examples 'deletion through allowed user' do
      it 'should respond with 202' do
        expect(subject.status).to eq 202
      end

      it 'should delete the account' do
        expect(User.exists?(user.id)).not_to be_truthy
      end

      context 'with a non-existent user' do
        let(:path) { api_v3_paths.user 1337 }

        it_behaves_like 'not found' do
          let(:id) { 1337 }
          let(:type) { 'User' }
        end
      end

      context 'with non-admin user' do
        let(:current_user) { FactoryGirl.create :user, admin: false }

        it 'responds with 403' do
          expect(subject.status).to eq 403
        end
      end
    end

    shared_examples 'deletion is not allowed' do
      it 'should respond with 403' do
        expect(subject.status).to eq 403
      end

      it 'should not delete the user' do
        expect(User.exists?(user.id)).to be_truthy
      end
    end

    context 'as admin' do
      let(:current_user) { FactoryGirl.create :admin }

      context 'with users deletable by admins' do
        let(:admin_delete) { true }

        it_behaves_like 'deletion through allowed user'
      end

      context 'with users not deletable by admins' do
        let(:admin_delete) { false }

        it_behaves_like 'deletion is not allowed'
      end
    end

    context 'as non-admin' do
      let(:current_user) { FactoryGirl.create :user, admin: false }

      it_behaves_like 'deletion is not allowed'
    end

    context 'as self' do
      let(:current_user) { user }

      context 'with self-deletion allowed' do
        let(:self_delete) { true }

        it_behaves_like 'deletion through allowed user'
      end

      context 'with self-deletion not allowed' do
        let(:self_delete) { false }

        it_behaves_like 'deletion is not allowed'
      end
    end

    context 'as anonymous user' do
      let(:current_user) { FactoryGirl.create :anonymous }

      it_behaves_like 'deletion is not allowed'
    end
  end
end
