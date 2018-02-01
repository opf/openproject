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

describe Member, type: :model do
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role) }
  let(:second_role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, user: user, roles: [role]) }

  describe '#add_role' do
    before do
      member.add_role(second_role)
      member.save!
      member.reload
    end

    context(:roles) do
      it { expect(member.roles).to include role }
      it { expect(member.roles).to include second_role }
    end
  end

  describe '#add_and_save_role' do
    before do
      member.add_and_save_role(second_role)
      member.reload
    end

    context(:roles) do
      it { expect(member.roles).to include role }
      it { expect(member.roles).to include second_role }
    end
  end

  describe '#assign_roles' do
    describe 'when replacing an existing role' do
      before do
        member.assign_roles([second_role])
        member.save!
        member.reload
      end
      context 'roles' do
        it { expect(member.roles).not_to include role }
        it { expect(member.roles).to include second_role }
      end
    end

    describe 'when assigning empty list of roles' do
      before do
        member.assign_roles([])
        res = member.save
      end

      context(:roles) do it { expect(member.roles).to include role } end
      context(:errors) { it { expect(member.errors.map { |_k, v| v }).to include 'Please choose at least one role.' } }
    end
  end

  describe '#assign_and_save_roles_and_destroy_member_if_none_left' do
    describe 'when replacing an existing role' do
      before do
        member.assign_and_save_roles_and_destroy_member_if_none_left([second_role])
        member.save!
        member.reload
      end
      context 'roles' do
        it { expect(member.roles).not_to include role }
        it { expect(member.roles).to include second_role }
      end
    end

    context 'when assigning an empty list of roles' do
      before do
        member.assign_and_save_roles_and_destroy_member_if_none_left([])
      end

      it('member should be destroyed') { expect(member.destroyed?).to eq(true) }
      context(:roles) { it { expect(member.roles.reload).to be_empty } }
    end
  end

  describe '#mark_member_role_for_destruction' do
    context 'after saving the member' do
      before do
        # Add a second role, since we can't remove the last one
        member.add_and_save_role(second_role)
        member.reload
        # Use member_roles(true) to make sure that all member roles are loaded,
        # otherwise ActiveRecord doesn't notice mark_for_destruction.
        member_role = member.member_roles.reload.first
        member.mark_member_role_for_destruction(member_role)
        member.save!
        member.reload
      end

      context(:roles) do it { expect(member.roles.length).to eq(1) } end
      context(:member_roles) { it { expect(member.member_roles.length).to eq(1) } }
    end

    context 'before saving the member when removing the last role' do
      before do
        member_role = member.member_roles.reload.first
        member.mark_member_role_for_destruction(member_role)
      end

      context(:roles) do it { expect(member.roles).not_to be_empty } end
      context(:member_roles) do it { expect(member.member_roles).not_to be_empty } end
      context(:member) { it { expect(member).not_to be_valid } }
    end
  end

  describe '#remove_member_role_and_destroy_member_if_last' do
    context 'when a member role remains' do
      before do
        # Add second role, so we can check it remains
        #
        # Order is important here to ensure we destroy the existing
        # member_role and not the one added by adding second_role.
        member_role = member.member_roles.reload.first

        member.add_and_save_role(second_role)

        member.remove_member_role_and_destroy_member_if_last(member_role)
      end

      it('member should not be destroyed') { expect(member.destroyed?).to eq(false) }
      context(:roles) do
        it { expect(member.roles.reload).to eq [second_role] }
      end
    end

    context 'when removing the last member role' do
      before do
        member_role = member.member_roles.reload.first
        member.remove_member_role_and_destroy_member_if_last(member_role)
      end

      it('member should be destroyed') { expect(member.destroyed?).to eq(true) }
      context(:roles) { it { expect(member.roles.reload).to be_empty } }
    end
  end
end
