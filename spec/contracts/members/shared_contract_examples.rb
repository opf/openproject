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

shared_examples_for 'member contract' do
  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && member_project == permission_project
      end
    end
  end
  let(:member_project) do
    FactoryBot.build_stubbed(:project)
  end
  let(:member_roles) do
    [FactoryBot.build_stubbed(:role)]
  end
  let(:member_principal) do
    FactoryBot.build_stubbed(:user)
  end
  let(:permissions) { [:manage_members] }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  describe 'validation' do
    shared_examples 'is valid' do
      it 'is valid' do
        expect_valid(true)
      end
    end

    it_behaves_like 'is valid'

    context 'if the roles are nil' do
      let(:member_roles) { [] }

      it 'is invalid' do
        expect_valid(false, roles: %i(role_blank))
      end
    end

    context 'if any role is not assignable (e.g. builtin)' do
      let(:member_roles) do
        [FactoryBot.build_stubbed(:role), FactoryBot.build_stubbed(:anonymous_role)]
      end

      it 'is invalid' do
        expect_valid(false, roles: %i(ungrantable))
      end
    end

    context 'if the user lacks :manage_members permission in the project' do
      let(:permissions) { [:view_members] }

      it 'is invalid' do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end
  end

  describe 'principal' do
    it 'returns the member\'s principal' do
      expect(contract.principal)
        .to eql(member.principal)
    end
  end

  describe 'project' do
    it 'returns the member\'s project' do
      expect(contract.project)
        .to eql(member.project)
    end
  end
end
