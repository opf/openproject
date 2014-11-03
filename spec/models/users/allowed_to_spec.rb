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

describe User, 'allowed_to?' do
  let(:user) { FactoryGirl.build(:user) }
  let(:anonymous) { FactoryGirl.build(:anonymous) }
  let(:project) { FactoryGirl.build(:project, is_public: false) }
  let(:project2) { FactoryGirl.build(:project, is_public: false) }
  let(:role) { FactoryGirl.build(:role) }
  let(:role2) { FactoryGirl.build(:role) }
  let(:anonymous_role) { FactoryGirl.build(:anonymous_role) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                            :roles => [role],
                                            :principal => user) }
  let(:member2) { FactoryGirl.build(:member, :project => project2,
                                             :roles => [role2],
                                             :principal => user) }

  before do
    user.save!
  end

  describe "w/ inquiring for projects" do
    describe "w/ the user being admin" do

      before do
        user.update_attribute(:admin, true)
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, project).should be_true
      end
    end

    describe "w/ the user being admin
              w/ the project being archived" do

      before do
        user.update_attribute(:admin, true)
        project.update_attribute(:status, Project::STATUS_ARCHIVED)
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, project).should be_false
      end
    end

    describe "w/ the user being admin
              w/ the project module the permission belongs to being inactive" do

      before do
        user.update_attribute(:admin, true)
        project.enabled_module_names = []
      end

      it "should be false" do
        expect(user.allowed_to?(:add_work_packages, project)).to be_false
      end
    end

    describe "w/ the user being a member in the project
              w/o the role having the necessary permission" do

      before do
        member.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, project).should be_false
      end
    end

    describe "w/ the user being a member in the project
              w/ the role having the necessary permission" do
      before do
        role.permissions << :add_work_packages

        member.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, project).should be_true
      end
    end

    describe "w/ the user being a member in the project
              w/ the role having the necessary permission
              w/o the module being active" do
      before do
        role.permissions << :view_news
        project.enabled_module_names = []

        member.save!
      end

      it "should be false" do
        expect(user.allowed_to?(:view_news, project)).to be_false
      end
    end

    describe "w/ the user being a member in the project
              w/ the role having the necessary permission
              w/ asking for a controller/action hash
              w/o the module being active" do
      before do
        role.permissions << :view_news
        project.enabled_module_names = []

        member.save!
      end

      it "should be false" do
        expect(user.allowed_to?({ controller: 'news', action: 'show' }, project)).to be_false
      end
    end

    describe "w/ the user being a member in the project
              w/o the role having the necessary permission
              w/ non members having the necessary permission" do
      before do
        project.is_public = false

        non_member = Role.non_member
        non_member.permissions << :add_work_packages
        non_member.save!

        member.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, project).should be_false
      end
    end

    describe "w/ the user being a member in the project
              w/o the role having the necessary permission
              w/ inquiring for a permission that is public" do
      before do
        project.is_public = false

        member.save!
      end

      it "should be true" do
        user.allowed_to?(:view_project, project).should be_true
      end
    end

    describe "w/o the user being member in the project
              w/ non member being allowed the action
              w/ the project being private" do
      before do
        project.is_public = false
        project.save!

        non_member = Role.non_member

        non_member.permissions << :add_work_packages
        non_member.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, project).should be_false
      end
    end

    describe "w/o the user being member in the project
              w/ the project being public
              w/ non members being allowed the action" do

      before do
        project.is_public = true
        project.save!

        non_member = Role.non_member

        non_member.permissions << :add_work_packages
        non_member.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, project).should be_true
      end
    end

    describe "w/ the user being anonymous
              w/ the project being public
              w/ anonymous being allowed the action" do

      before do
        project.is_public = true
        project.save!

        anonymous_role.permissions << :add_work_packages
        anonymous_role.save!
      end

      it "should be true" do
        anonymous.allowed_to?(:add_work_packages, project).should be_true
      end
    end

    describe "w/ the user being anonymous
              w/ the project being public
              w/ querying for a public permission" do

      before do
        project.is_public = true
        project.save!

        anonymous_role.save!
      end

      it "should be true" do
        anonymous.allowed_to?(:view_project, project).should be_true
      end
    end

    describe "w/ the user being anonymous
              w/ requesting a controller and action allowed by multiple permissions
              w/ the project beeing public
              w/ anonymous being allowed the action" do
      before do
        project.is_public = true
        project.save!

        anonymous_role.permissions << :manage_categories
        anonymous_role.save!
      end

      it "should be true" do
        anonymous.allowed_to?( { :controller => 'projects', :action => 'settings' }, project).should be_true
      end
    end

    describe "w/ the user being anonymous
              w/ the project being public
              w/ anonymous being not allowed the action" do

      before do
        project.is_public = true
        project.save!
      end

      it "should be false" do
        anonymous.allowed_to?(:add_work_packages, project).should be_false
      end
    end

    describe "w/ the user being a member in two projects
              w/ the user being allowed the action in both projects" do

      before do
        role.permissions << :add_work_packages
        role2.permissions << :add_work_packages

        member.save!
        member2.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, [project, project2]).should be_true
      end
    end

    describe "w/ the user being a member in two projects
              w/ the user being allowed in only one project" do

      before do
        role.permissions << :add_work_packages

        member.save!
        member2.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, [project, project2]).should be_false
      end
    end

    describe "w/o the user being a member in the two projects
              w/ both projects being public
              w/ non member being allowed the action" do

      before do
        non_member = Role.non_member
        non_member.permissions << :add_work_packages
        non_member.save!

        project.update_attribute(:is_public, true)
        project2.update_attribute(:is_public, true)
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, [project, project2]).should be_true
      end
    end

    describe "w/o the user being a member in the two projects
              w/ only one project being public
              w/ non member being allowed the action" do

      before do
        non_member = Role.non_member
        non_member.permissions << :add_work_packages
        non_member.save!

        project.update_attribute(:is_public, true)
        project2.update_attribute(:is_public, false)
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, [project, project2]).should be_false
      end
    end

    describe "w/ requesting a controller and action
              w/ the user being allowed the action" do
      before do
        role.permissions << :add_work_packages

        member.save!
      end

      it "should be true" do
        user.allowed_to?( { :controller => 'work_packages', :action => 'new' }, project).should be_true
      end
    end

    describe "w/ requesting a controller and action allowed by multiple permissions
              w/ the user being allowed the action" do
      before do
        role.permissions << :manage_categories

        member.save!
      end

      it "should be true" do
        user.allowed_to?( { :controller => 'projects', :action => 'settings' }, project).should be_true
      end
    end
  end

  describe "w/ inquiring globally" do
    describe "w/ the user being admin" do

      before do
        user.admin = true
        user.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, nil, global: true).should be_true
      end
    end

    describe "w/ the user being a member in a project
              w/o the role having the necessary permission" do

      before do
        member.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, nil, global: true).should be_false
      end
    end

    describe "w/ the user being a member in the project
              w/ the role having the necessary permission" do
      before do
        role.permissions << :add_work_packages

        member.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, nil, global: true).should be_true
      end
    end

    describe "w/ the user being a member in the project
              w/ inquiring for controller and action
              w/ the role having the necessary permission" do
      before do
        role.permissions << :add_work_packages

        member.save!
      end

      it "should be true" do
        user.allowed_to?( { :controller => 'work_packages', :action => 'new' }, nil, global: true).should be_true
      end
    end

    describe "w/ the user being a member in the project
              w/o the role having the necessary permission
              w/ non members having the necessary permission" do
      before do
        non_member = Role.non_member
        non_member.permissions << :add_work_packages
        non_member.save!

        member.save!
      end

      it "should be false" do
        user.allowed_to?(:add_work_packages, nil, global: true).should be_false
      end
    end

    describe "w/o the user being a member in the project
              w/ non members being allowed the action" do

      before do
        non_member = Role.non_member
        non_member.permissions << :add_work_packages
        non_member.save!
      end

      it "should be true" do
        user.allowed_to?(:add_work_packages, nil, global: true).should be_true
      end
    end

    describe "w/ the user being anonymous
              w/ anonymous being allowed the action" do

      before do
        anonymous_role.permissions << :add_work_packages
        anonymous_role.save!
      end

      it "should be true" do
        anonymous.allowed_to?(:add_work_packages, nil, global: true).should be_true
      end
    end

    describe "w/ requesting a controller and action allowed by multiple permissions
              w/ the user being a member in the project
              w/o the role having the necessary permission
              w/ non members having the necessary permission" do
      before do
        non_member = Role.non_member
        non_member.permissions << :manage_categories
        non_member.save!

        member.save!
      end

      it "should be true" do
        user.allowed_to?( { :controller => 'projects', :action => 'settings' }, nil, global: true).should be_false
      end
    end

    describe "w/ the user being anonymous
              w/ anonymous being not allowed the action" do

      it "should be false" do
        anonymous.allowed_to?(:add_work_packages, nil, global: true).should be_false
      end
    end
  end
end
