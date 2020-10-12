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

describe User, 'allowed to' do
  let(:user) { member.principal }
  let(:anonymous) { FactoryBot.build(:anonymous) }
  let(:project) { FactoryBot.build(:project, public: false) }
  let(:project2) { FactoryBot.build(:project, public: false) }
  let(:role) { FactoryBot.build(:role) }
  let(:role2) { FactoryBot.build(:role) }
  let(:anonymous_role) { FactoryBot.build(:anonymous_role) }
  let(:member) { FactoryBot.build(:member, project:  project,
                                            roles: [role]) }

  let(:action) { :the_one }
  let(:other_action) { :another }
  let(:public_action) { :view_project }
  let(:global_permission) { OpenProject::AccessControl.permissions.find { |p| p.global? } }
  let(:global_role) { FactoryBot.build(:global_role, :permissions => [global_permission.name]) }
  let(:principal_role) { FactoryBot.build(:empty_principal_role, principal: user,
                                                                  role: global_role) }


  before do
    user.save!
    anonymous.save!
  end

  context "w/o the context being a project
           w/o the user being member in a project
           w/ the user having the global role
           w/ the global role having the necessary permission" do
    before do
      global_role.save!

      principal_role.save!
    end

    it 'is true' do
      expect(user.allowed_to?(global_permission.name, nil, global: true)).to be_truthy
    end
  end

  context "w/o the context being a project
           w/o the user being member in a project
           w/ the user having the global role
           w/o the global role having the necessary permission" do

    before do
      global_role.permissions = []
      global_role.save!

      principal_role.save!
    end

    it 'is false' do
      expect(user.allowed_to?(global_permission.name, nil, global: true)).to be_falsey
    end
  end

  context "w/o the context being a project
           w/o the user being member in a project
           w/o the user having the global role
           w/ the global role having the necessary permission" do

    before do
      global_role.permissions = []
      global_role.save!
    end

    it 'is false' do
      expect(user.allowed_to?(global_permission.name, nil, global: true)).to be_falsey
    end
  end

  context "w/o the context being a project
           w/o the user being member in a project
           w/o the user having the global role
           w/ the user being admin" do

    before do
      user.update_attribute(:admin, true)
    end

    it 'is true' do
      expect(user.allowed_to?(global_permission.name, nil, global: true)).to be_truthy
    end
  end

  context "w/ the context being a project
           w/o the user being member in the project
           w/ the user having the global role
           w/o the global role having the necessary permission" do
    before do
      global_role.permissions = []
      global_role.save!

      principal_role.save!
    end

    it 'is false' do
      expect(user.allowed_to?(global_permission.name, project)).to be_falsey
    end
  end

  context "w/ the context being a project
           w/o the user being member in a project
           w/o the user having the global role
           w/ the global role having the necessary permission" do

    before do
      global_role.permissions = []
      global_role.save!
    end

    it 'is false' do
      expect(user.allowed_to?(global_permission.name, project)).to be_falsey
    end
  end

  context "w/ the context being a project
           w/o the user being member in a project
           w/o the user having the global role
           w/ the user being admin" do

    before do
      user.update_attribute(:admin, true)
    end

    it 'is true' do
      expect(user.allowed_to?(global_permission.name, project)).to be_truthy
    end
  end
end

