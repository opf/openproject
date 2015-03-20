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

describe 'API v3 UserLock resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryGirl.build_stubbed(:user) }
  let(:user) { FactoryGirl.create(:user, status: User::STATUSES[:active]) }
  let(:model) { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { ::API::V3::Users::UserRepresenter.new(model) }
  let(:lock_path) { api_v3_paths.user_lock user.id }
  subject(:response) { last_response }

  describe '#post' do
    before do
      allow(User).to receive(:current).and_return current_user
      post lock_path
      # lock manually
      user.lock
    end

    # Locking is only available for admins
    context 'when logged in as admin' do
      let(:current_user) { FactoryGirl.build_stubbed(:admin) }

      context 'user account can be locked' do
        it 'should respond with 200' do
          expect(subject.status).to eq(200)
        end

        it 'should respond with an updated lock status in the user model' do
          expect(parse_json(subject.body, 'status')).to eq 'locked'
        end
      end

      context 'user account is incompatible' do
        let(:user) {
          FactoryGirl.create(:user, status: User::STATUSES[:registered])
        }
        it 'should fail for invalid transitions' do
          expect(subject.status).to eq(400)
        end
      end
    end

    context 'requesting nonexistent user' do
      let(:lock_path) { api_v3_paths.user_lock 9999 }
      it_behaves_like 'not found' do
        let(:id) { 9999 }
        let(:type) { 'User' }
      end
    end

    context 'non-admin user' do
      it 'should respond with 403' do
        expect(subject.status).to eq(403)
      end
    end
  end

  describe '#delete' do
    before do
      allow(User).to receive(:current).and_return current_user
      delete lock_path
      # unlock manually
      user.activate
    end

    # Unlocking is only available for admins
    context 'when logged in as admin' do
      let(:current_user) { FactoryGirl.build_stubbed(:admin) }

      context 'user account can be unlocked' do
        it 'should respond with 200' do
          expect(subject.status).to eq(200)
        end

        it 'should respond with an updated lock status in the user model' do
          expect(parse_json(subject.body, 'status')).to eq 'active'
        end
      end

      context 'user account is incompatible' do
        let(:user) {
          FactoryGirl.create(:user, status: User::STATUSES[:registered])
        }
        it 'should fail for invalid transitions' do
          expect(subject.status).to eq(400)
        end
      end
    end

    context 'non-admin user' do
      it 'should respond with 403' do
        expect(subject.status).to eq(403)
      end
    end
  end
end
