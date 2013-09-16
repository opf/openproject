#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe Member do
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role) }
  let(:second_role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, :user => user, :roles => [role]) }

  describe '#add_role' do
    before do
      member.add_role(second_role)
      member.save!
      member.reload
    end

    context(:roles) do
      it { member.roles.should include role }
      it { member.roles.should include second_role }
    end
  end

  describe '#add_and_save_role' do
    before do
      member.add_and_save_role(second_role)
      member.reload
    end

    context(:roles) do
      it { member.roles.should include role }
      it { member.roles.should include second_role }
    end
  end

  describe '#assign_roles' do
    describe 'when replacing an existing role' do
      before do
        member.assign_roles([second_role])
        member.save!
        member.reload
      end
      context :roles do
        it { member.roles.should_not include role }
        it { member.roles.should include second_role }
      end
    end

    describe 'when assigning empty list of roles' do
      before do
        member.assign_roles([])
        res = member.save
      end

      context(:roles) { it { member.roles.should include role } }
      context(:errors) { it { member.errors[:roles].should include "can't be empty" } }
    end
  end

  describe "#assign_and_save_roles_and_destroy_member_if_none_left" do
    describe 'when replacing an existing role' do
      before do
        member.assign_and_save_roles_and_destroy_member_if_none_left([second_role])
        member.save!
        member.reload
      end
      context :roles do
        it { member.roles.should_not include role }
        it { member.roles.should include second_role }
      end
    end

    context 'when assigning an empty list of roles' do
      before do
        member.assign_and_save_roles_and_destroy_member_if_none_left([])
      end

      it('member should be destroyed') { member.destroyed?.should == true }
      context(:roles) { it { member.roles(true).should be_empty } }
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
        member_role = member.member_roles(true).first
        member.mark_member_role_for_destruction(member_role)
        member.save!
        member.reload
      end

      context(:roles) { it { member.roles.length.should == 1 } }
      context(:member_roles) { it { member.member_roles.length.should == 1 } }
    end

    context 'before saving the member when removing the last role' do
      before do
        member_role = member.member_roles(true).first
        member.mark_member_role_for_destruction(member_role)
      end

      context(:roles) { it { member.roles.should_not be_empty } }
      context(:member_roles) { it { member.member_roles.should_not be_empty } }
      context(:member) { it { member.should_not be_valid } }
    end
  end

  describe '#remove_member_role_and_destroy_member_if_last' do
    context 'when a member role remains' do
      before do
        # Add second role, so we can check it remains
        member.add_and_save_role(second_role)

        member_role = member.member_roles(true).first
        member.remove_member_role_and_destroy_member_if_last(member_role)
      end

      it('member should not be destroyed') { member.destroyed?.should == false }
      context(:roles) do
        it { member.roles(true).length.should == 1 }
        it { member.roles(true).first.id.should == second_role.id }
      end
    end

    context 'when removing the last member role' do
      before do
        member_role = member.member_roles(true).first
        member.remove_member_role_and_destroy_member_if_last(member_role)
      end

      it('member should be destroyed') { member.destroyed?.should == true }
      context(:roles) { it { member.roles(true).should be_empty } }
    end
  end
end
