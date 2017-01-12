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

describe 'API v3 User resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.create(:user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:model) { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { ::API::V3::Users::UserRepresenter.new(model) }

  subject(:response) { last_response }

  describe '#index' do
    let(:get_path) { api_v3_paths.users }

    before do
      user
      allow(User).to receive(:current).and_return current_user
      get get_path
    end

    context 'admin user' do
      let(:current_user) { FactoryGirl.create(:admin) }

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      # note that the order of the users is depending on the id
      # meaning the order in which they where saved
      it 'contains the user in the response' do
        expect(subject.body)
          .to be_json_eql(user.name.to_json)
          .at_path('_embedded/elements/0/name')
      end

      it 'contains the current user in the response' do
        expect(subject.body)
          .to be_json_eql(current_user.name.to_json)
          .at_path('_embedded/elements/1/name')
      end

      it 'has the users index path for link self href' do
        expect(subject.body)
          .to be_json_eql((api_v3_paths.users + '?offset=1&pageSize=30').to_json)
          .at_path('_links/self/href')
      end

      context 'if pageSize = 1 and offset = 2' do
        let(:get_path) { api_v3_paths.users + '?pageSize=1&offset=2' }

        it 'contains the current user in the response' do
          expect(subject.body)
            .to be_json_eql(current_user.name.to_json)
            .at_path('_embedded/elements/0/name')
        end
      end

      context 'on filtering for name' do
        let(:get_path) do
          filter = [{ 'name' => {
            'operator' => '~',
            'values' => [user.name]
          } }]

          "#{api_v3_paths.users}?#{{ filters: filter.to_json }.to_query}"
        end

        it 'contains the filtered user in the response' do
          expect(subject.body)
            .to be_json_eql(user.name.to_json)
            .at_path('_embedded/elements/0/name')
        end

        it 'contains no more users' do
          expect(subject.body)
            .to be_json_eql(1.to_json)
            .at_path('total')
        end
      end

      context 'on sorting' do
        let(:users_by_name_order) do
          User.not_builtin.order_by_name.reverse_order
        end

        let(:get_path) do
          sort = [['name', 'desc']]

          "#{api_v3_paths.users}?#{{ sortBy: sort.to_json }.to_query}"
        end

        it 'contains the first user as the first element' do
          expect(subject.body)
            .to be_json_eql(users_by_name_order[0].name.to_json)
            .at_path('_embedded/elements/0/name')
        end

        it 'contains the first user as the second element' do
          expect(subject.body)
            .to be_json_eql(users_by_name_order[1].name.to_json)
            .at_path('_embedded/elements/1/name')
        end
      end

      context 'on an invalid filter' do
        let(:get_path) do
          filter = [{ 'name' => {
            'operator' => 'a',
            'values' => [user.name]
          } }]

          "#{api_v3_paths.users}?#{{ filters: filter.to_json }.to_query}"
        end

        it 'returns an error' do
          expect(subject.status).to eql(400)
        end
      end
    end

    context 'other user' do
      it 'should respond with 403' do
        expect(subject.status).to eq(403)
      end
    end
  end

  describe '#get' do
    context 'logged in user' do
      let(:get_path) { api_v3_paths.user user.id }
      before do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct body' do
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

    context 'get with login' do
      let(:get_path) { api_v3_paths.user user.login }
      before do
        allow(User).to receive(:current).and_return current_user
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it 'should respond with correct body' do
        expect(subject.body).to be_json_eql(user.name.to_json).at_path('name')
      end
    end

    it_behaves_like 'handling anonymous user' do
      let(:path) { api_v3_paths.user user.id }
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
