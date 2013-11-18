#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Principal do
  describe "ATTRIBUTES" do
    before :each do

    end

    it { should have_many :principal_roles }
    it { should have_many :global_roles }

  end

  describe "WHEN deleting a principal" do
    let(:principal) { FactoryGirl.build(:user) }
    let(:role) { FactoryGirl.build(:global_role) }

    before do
      FactoryGirl.create(:principal_role, :role => role,
                                      :principal => principal)
      principal.destroy
    end

    it { Role.find_by_id(role.id).should == role }
    it { PrincipalRole.find_all_by_principal_id(principal.id).should == [] }
  end
end
