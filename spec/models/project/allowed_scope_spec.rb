#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe Project, 'allowed scope' do
  let(:user) { FactoryGirl.build(:user) }
  let(:anonymous) { FactoryGirl.build(:anonymous) }
  let(:project) { FactoryGirl.build(:project, is_public: false) }
  let(:project2) { FactoryGirl.build(:project, is_public: false) }
  let(:role) { FactoryGirl.build(:role) }
  let(:role2) { FactoryGirl.build(:role) }
  let(:non_member_role) { FactoryGirl.build(:non_member) }
  let(:anonymous_role) { FactoryGirl.build(:anonymous_role) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                            :roles => [role],
                                            :principal => user) }
  let(:member2) { FactoryGirl.build(:member, :project => project2,
                                             :roles => [role2],
                                             :principal => user) }
  let(:permission) { :a_permission }
  let(:public_permission) { Redmine::AccessControl.public_permissions.first.name }

  before do
    project.save!
    project2.save!

    user.save!
  end

  describe "w/ non public projects" do
    describe "w/ the user being admin" do
      before do
        user.update_attribute(:admin, true)
      end

      it "should return all projects" do
        expect(Project.allowed(user).all).to match_array([project, project2])
      end
    end

    describe "w/o the user being admin" do

      it "should be empty" do
        expect(Project.allowed(user).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/o querying for a specific permission" do
      before do
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user).all).to eq([project])
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user has" do
      before do
        role.permissions << permission
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user, permission).all).to eq([project])
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user does not have" do
      before do
        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user has
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        role.permissions << permission.name
        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission.name).all).to be_empty
      end
    end

    describe "w/ the user being admin
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        user.update_attribute(:admin, true)
      end

      it "should include only projects that have the module enabled" do
        expect(Project.allowed(user, permission.name).all).to eq [project2]
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user does not have
              w/ querying for a permission the non_member role has" do
      before do
        non_member_role.permissions << permission
        non_member_role.save!

        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/ querying for a public permission" do
      before do
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user, public_permission).all).to eq([project])
      end
    end

    describe "w/o the user being member
              w/ querying for a public permission" do

      it "should be empty" do
        expect(Project.allowed(user, public_permission).all).to be_empty
      end
    end

    describe "w/ the user being anonymous
              w/ the anonymous role having the permission" do
      before do
        anonymous_role.permissions << permission
        anonymous_role.save!
      end

      it "should be empty" do
        expect(Project.allowed(anonymous, permission).all).to be_empty
      end
    end

    describe "w/ the user being admin
              w/ a project being archived" do
      before do
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
        user.update_attribute(:admin, true)
      end

      it "should return non archived" do
        expect(Project.allowed(user).all).to match_array([project2])
      end
    end

    describe "w/ the user being member
              w/ querying for a public permission
              w/ the project being archived" do
      before do
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, public_permission).all).to be_empty
      end
    end
  end

  describe "w/ public projects" do
    before do
      project.update_attribute(:is_public, true)
    end

    describe "w/ the user being admin" do
      before do
        user.update_attribute(:admin, true)
      end

      it "should return all projects" do
        expect(Project.allowed(user).all).to match_array [project, project2]
      end
    end

    describe "w/o the user being admin (making him a non member)
              w/o querying for a specific permission" do

      it "should return the public project" do
        expect(Project.allowed(user).all).to eq [project]
      end
    end

    describe "w/ the user being member" do
      before do
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user).all).to eq([project])
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user has" do
      before do
        role.permissions << permission
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user, permission).all).to eq([project])
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user does not have" do
      before do
        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user does not have
              w/ querying for a permission the non_member role has" do
      before do
        non_member_role.permissions << permission
        non_member_role.save!

        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/ querying for a public permission" do
      before do
        member.save!
      end

      it "should return the project" do
        expect(Project.allowed(user, public_permission).all).to eq([project])
      end
    end

    describe "w/o the user being member
              w/ querying for a public permission" do

      it "should return the project" do
        # because the non member has the permission
        expect(Project.allowed(user, public_permission).all).to eq([project])
      end
    end

    describe "w/o the user being member
              w/ querying for a permission the non_member role has" do
      before do
        non_member_role.permissions << permission
        non_member_role.save!
      end

      it "should return the project" do
        expect(Project.allowed(user, permission).all).to eq([project])
      end
    end

    describe "w/ the user being anonymous
              w/ the anonymous having the permission" do
      before do
        anonymous_role.permissions << permission
        anonymous_role.save!
      end

      it "should return the project" do
        expect(Project.allowed(anonymous, permission).all).to eq [project]
      end
    end

    describe "w/ the user being anonymous
              w/o the anonymous having the permission" do

      it "should be empty" do
        expect(Project.allowed(anonymous, permission).all).to be_empty
      end
    end

    describe "w/ the user being anonymous
              w/ querying for a public permission" do

      it "should return the project" do
        expect(Project.allowed(anonymous, public_permission).all).to eq [project]
      end
    end

    describe "w/ the user being member
              w/ querying for a public permission" do
      before do
        member.save!
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
      end

      it "should be empty" do
        expect(Project.allowed(user, public_permission).all).to be_empty
      end
    end

    describe "w/o the user being member
              w/ querying for a permission the non_member role has
              w/ the project being archived" do

      before do
        non_member_role.permissions << permission
        non_member_role.save!
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
      end

      it "should be empty" do
        expect(Project.allowed(user, permission).all).to be_empty
      end
    end

    describe "w/ the user being anonymous
              w/ querying for a public permission
              w/ the project being archived" do

      before do
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
      end

      it "should be empty" do
        expect(Project.allowed(anonymous, public_permission).all).to be_empty
      end
    end

    describe "w/ the user being member
              w/ querying for a permission the user has
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        role.permissions << permission.name
        member.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission.name).all).to be_empty
      end
    end

    describe "w/ the user being admin
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        user.update_attribute(:admin, true)
      end

      it "should include only projects that have the module enabled" do
        expect(Project.allowed(user, permission.name).all).to eq [project2]
      end
    end

    describe "w/o the user being member
              w/ querying for a permission the non member role has
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        non_member_role.permissions << permission.name
        non_member_role.save!
      end

      it "should be empty" do
        expect(Project.allowed(user, permission.name).all).to be_empty
      end
    end

    describe "w/ the user being anonymous
              w/ querying for a permission the anonymous role has
              w/o the project module the permission belongs to being active in the project" do

      let(:permission) do
        Redmine::AccessControl.permissions.find{ |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        anonymous_role.permissions << permission.name
        anonymous_role.save!
      end

      it "should be empty" do
        expect(Project.allowed(anonymous, permission.name).all).to be_empty
      end
    end
  end
end
