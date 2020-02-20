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

describe Role, type: :model do
  let(:permissions) { [:permission1, :permission2] }
  let(:build_role) { FactoryBot.build(:role, permissions: permissions) }
  let(:created_role) { FactoryBot.create(:role, permissions: permissions) }

  describe '#by_permission' do
    it 'returns roles with given permission' do
      created_role

      expect(Role.by_permission(permissions[0])).to include created_role
      expect(Role.by_permission(:some_other)).not_to include created_role
    end
  end

  describe '#permissions' do
    shared_examples_for 'writing and reading' do
      it 'returns the values written before' do
        perms = permissions + [:permission3]

        role.permissions = perms

        expect(role.permissions).to match_array(perms)
      end

      it 'removes empty permissions' do
        perms = permissions + ['']

        role.permissions = perms

        expect(role.permissions).to match_array(permissions)
      end

      it 'does not readd permissions' do
        perms = permissions + permissions.map(&:to_s)

        role.permissions = perms

        expect(role.permissions).to match_array(permissions)
      end

      it 'allows clearing the permissions' do
        role.permissions = []

        expect(role.permissions).to be_empty
      end
    end

    context 'for a non persisted role' do
      let(:role) { build_role }

      it_behaves_like 'writing and reading'
    end

    context 'for a persisted role' do
      let(:role) { created_role }

      it_behaves_like 'writing and reading'
    end
  end

  describe '#remove_permission!' do
    shared_examples_for 'removing' do
      it 'removes the specified permission' do
        perm = permissions.first

        role.remove_permission!(perm)

        expect(role.role_permissions.map(&:permission)).not_to include perm.to_s
      end
    end

    context 'for a non persisted role' do
      let(:role) { build_role }

      it_behaves_like 'removing'
    end

    context 'for a persisted role' do
      let(:role) { created_role }

      it_behaves_like 'removing'
    end
  end

  describe '#add_permission!' do
    shared_examples_for 'adding' do
      it 'adds the specified permission' do
        role.add_permission!(:permission3)

        expect(role.role_permissions.map(&:permission)).to include 'permission3'
      end
    end

    context 'for a non persisted role' do
      let(:role) { build_role }

      it_behaves_like 'adding'
    end

    context 'for a persisted role' do
      let(:role) { created_role }

      it_behaves_like 'adding'
    end
  end

  describe '.givable' do
    before do
      # this should not be necessary once Role (in a membership) and GlobalRole have
      # a common ancestor class, e.g. Role (a new one)
      @mem_role1 = Role.create name: 'mem_role', permissions: []
      @builtin_role1 = Role.new name: 'builtin_role1', permissions: []
      @builtin_role1.builtin = 3
      @builtin_role1.save
      @global_role1 = GlobalRole.create name: 'global_role1', permissions: []
    end

    it { expect(Role.givable.size).to eq(1) }
    it { expect(Role.givable[0]).to eql @mem_role1 }
  end

  describe '.in_new_project' do
    let!(:ungivable_role) { FactoryBot.create(:role, builtin: Role::BUILTIN_NON_MEMBER) }
    let!(:second_role) do
      FactoryBot.create(:role).tap do |r|
        r.update_column(:position, 100)
      end
    end
    let!(:first_role) do
      FactoryBot.create(:role).tap do |r|
        r.update_column(:position, 1)
      end
    end

    context 'without a specified role' do
      it 'returns the first role (by position)' do
        expect(Role.in_new_project)
          .to eql first_role
      end
    end

    context 'with a specified role' do
      before do
        allow(Setting)
          .to receive(:new_project_user_role_id)
          .and_return(second_role.id.to_s)
      end

      it 'returns that role' do
        expect(Role.in_new_project)
          .to eql second_role
      end
    end

    context 'with a specified role but that one is faulty (e.g. does not exist any more)' do
      before do
        allow(Setting)
          .to receive(:new_project_user_role_id)
          .and_return("-1")
      end

      it 'returns the first role (by position)' do
        expect(Role.in_new_project)
          .to eql first_role
      end
    end
  end
end
