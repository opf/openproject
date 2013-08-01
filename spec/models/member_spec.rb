#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Member do
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role) }
  let(:second_role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, :user => user, :roles => [role]) }
  let(:unsaved_member) { FactoryGirl.build(:member, :user => user) }

  describe "#roles=" do
    context 'member with all roles removed' do
      before do
        unsaved_member.roles = [role]
        unsaved_member.save!
        unsaved_member.member_roles.each(&:mark_for_destruction)
        unsaved_member.valid?  # run validations
      end

      it { unsaved_member.should_not be_valid }
      it { unsaved_member.role_ids.should == [role.id] }
      context 'errors' do
        it { unsaved_member.errors[:roles].should include "can't be empty" }
      end
    end
  end

  describe '#assign_roles' do
    describe 'replacing an existing role and saving manually' do
      before do
        member.assign_roles([second_role], false)
        member.save
        member.reload
      end
      context :roles do
        it { member.roles.should_not include role }
        it { member.roles.should include second_role }
      end
    end

    describe 'setting to having no roles and saving manually' do
      before do
        member.assign_roles([], false)
        res = member.save
      end

      context(:roles) { it { member.roles.should include role } }
      context(:errors) { it { member.errors[:roles].should include "can't be empty" } }
    end
  end

  describe '#add_role' do
    describe 'saving manually' do
      before do
        member.add_role(second_role)
        member.save
        member.reload
      end

      context(:roles) { it { member.roles.should include role } }
      context(:roles) { it { member.roles.should include second_role } }
    end
  end

  describe '#remove_member_role' do
    before do
      member_role = member.member_roles.first
      member.remove_member_role(member_role)
      member.save
      member.reload
    end

    context(:roles) { it { member.roles.should be_empty } }
    context(:member_roles) { it { member.member_roles.should be_empty } }
  end
end
