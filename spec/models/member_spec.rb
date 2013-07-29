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
  let(:member) { FactoryGirl.build(:member, :user => user) }

  it "fails to save members with all roles marked for destruction" do
    member.roles = [role]
    member.save!
    member.member_roles.each(&:mark_for_destruction)
    member.should_not be_valid
    member.errors[:roles].should include "can't be empty"
    member.role_ids.should == [role.id]
  end
end
