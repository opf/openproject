#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Users::CreateContract do
  let(:user) { FactoryBot.build_stubbed(:user) }

  subject(:contract) { described_class.new(user, current_user) }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  context 'when admin' do
    let(:current_user) { FactoryBot.build_stubbed(:admin) }

    it_behaves_like 'is valid'

    describe 'requires a password set when active' do
      before do
        user.password = nil
        user.activate
      end

      it 'is invalid' do
        expect_valid(false, password: %i(blank))
      end

      context 'when password is set' do
        before do
          user.password = user.password_confirmation = 'password!password!'
        end

        it_behaves_like 'is valid'
      end
    end
  end

  context 'when global user' do
    let!(:global_add_user_role) { FactoryBot.create :global_role, name: 'Add user', permissions: %i[add_user] }
    let(:current_user) do
      user = FactoryBot.create(:user)

      FactoryBot.create(:global_member,
                        principal: user,
                        roles: [global_add_user_role])

      user
    end

    describe 'can invite user' do
      before do
        user.password = user.password_confirmation = nil
        user.mail = 'foo@example.com'
        user.invite
      end

      it_behaves_like 'is valid'
    end

    describe 'cannot set the password' do
      before do
        user.password = user.password_confirmation = 'password!password!'
      end

      it 'is invalid' do
        expect_valid(false, password: %i(error_readonly))
      end
    end

    describe 'cannot set the auth_source' do
      let!(:auth_source) { FactoryBot.create :auth_source }

      before do
        user.auth_source = auth_source
      end

      it 'is invalid' do
        expect_valid(false, auth_source_id: %i(error_readonly))
      end
    end

    describe 'cannot set the identity url' do
      before do
        user.identity_url = 'saml:123412foo'
      end

      it 'is invalid' do
        expect_valid(false, identity_url: %i(error_readonly))
      end
    end
  end

  context 'when unauthorized user' do
    let(:current_user) { FactoryBot.build_stubbed(:user) }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end
end
