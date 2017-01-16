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

describe Authorization::UserAllowedQuery do
  describe '.query' do
    let(:user) { member.principal }
    let(:anonymous) { FactoryGirl.build(:anonymous) }
    let(:project) { FactoryGirl.build(:project, is_public: false) }
    let(:project2) { FactoryGirl.build(:project, is_public: false) }
    let(:role) { FactoryGirl.build(:role) }
    let(:role2) { FactoryGirl.build(:role) }
    let(:anonymous_role) { FactoryGirl.build(:anonymous_role) }
    let(:non_member_role) { FactoryGirl.build(:non_member) }
    let(:member) do
      FactoryGirl.build(:member, project: project,
                                 roles: [role])
    end

    let(:action) { :view_work_packages }
    let(:other_action) { :another }
    let(:public_action) { :view_project }

    before do
      user.save!
      anonymous.save!
      anonymous_role.save!
      non_member_role.save!
    end

    it 'is a user relation' do
      expect(described_class.query(action, project)).to be_a User::ActiveRecord_Relation
    end

    context 'w/o the project being public
             w/ the user being member in the project
             w/ the role having the necessary permission' do
      before do
        role.add_permission! action
        role.save!

        member.save!
      end

      it 'should return the user' do
        expect(described_class.query(action, project)).to match_array [user]
      end
    end

    context 'w/o the project being public
             w/o the user being member in the project
             w/ the user being admin' do
      before do
        user.update_attribute(:admin, true)
      end

      it 'should return the user' do
        expect(described_class.query(action, project)).to match_array [user]
      end
    end

    context 'w/o the project being public
             w/ the user being member in the project
             w/o the role having the necessary permission' do
      before do
        role.save!
        member.save!
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/o the project being public
             w/o the user being member in the project
             w/ the role having the necessary permission' do
      before do
        role.add_permission! action
        role.save!
      end

      it 'should return the user' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/o the project being public
             w/o the user being member in the project
             w/ the user being member in a different project
             w/ the role having the permission' do
      before do
        role.add_permission! action
        role.save!

        member.project = project2
        member.save!
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/ the project being public
             w/o the user being member in the project
             w/ the user being member in a different project
             w/ the role having the permission' do
      before do
        role.add_permission! action
        role.save!

        project.is_public = true
        project.save!

        member.project = project2
        member.save!
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/ the project being public
             w/o the user being member in the project
             w/ the non member role having the necessary permission' do
      before do
        project.is_public = true

        non_member = Role.non_member
        non_member.add_permission! action
        non_member.save

        project.save!
      end

      it 'should return the user' do
        expect(described_class.query(action, project)).to match_array [user]
      end
    end

    context 'w/ the project being public
             w/o the user being member in the project
             w/ the anonymous role having the necessary permission' do
      before do
        project.is_public = true

        anonymous_role = Role.anonymous
        anonymous_role.add_permission! action
        anonymous_role.save

        project.save!
      end

      it 'should return the anonymous user' do
        expect(described_class.query(action, project)).to match_array([anonymous])
      end
    end

    context 'w/ the project being public
             w/o the user being member in the project
             w/ the non member role having another permission' do
      before do
        project.is_public = true

        non_member = Role.non_member
        non_member.add_permission! other_action
        non_member.save

        project.save!
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/ the project being private
             w/o the user being member in the project
             w/ the non member role having the permission' do
      before do
        non_member = Role.non_member
        non_member.add_permission! action
        non_member.save

        project.save!
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/ the project being public
             w/ the user being member in the project
             w/o the role having the necessary permission
             w/ the non member role having the permission' do
      before do
        project.is_public = true
        project.save

        role.add_permission! other_action
        member.save!

        non_member = Role.non_member
        non_member.add_permission! action
        non_member.save
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to be_empty
      end
    end

    context 'w/o the project being public
             w/ the user being member in the project
             w/o the role having the permission
             w/ the permission being public' do
      before do
        member.save!
      end

      it 'should return the user' do
        expect(described_class.query(public_action, project)).to match_array [user]
      end
    end

    context 'w/ the project being public
             w/o the user being member in the project
             w/o the role having the permission
             w/ the permission being public' do
      before do
        project.is_public = true
        project.save
      end

      it 'should return the user and anonymous' do
        expect(described_class.query(public_action, project)).to match_array [user, anonymous]
      end
    end

    context 'w/ the user being member in the project
             w/ asking for a certain permission
             w/ the permission belonging to a module
             w/o the module being active' do
      let(:permission) do
        Redmine::AccessControl.permissions.find { |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = []

        role.add_permission! permission.name
        member.save!
      end

      it 'should be empty' do
        expect(described_class.query(permission.name, project)).to eq []
      end
    end

    context 'w/ the user being member in the project
             w/ asking for a certain permission
             w/ the permission belonging to a module
             w/ the module being active' do
      let(:permission) do
        Redmine::AccessControl.permissions.find { |p| p.project_module.present? }
      end

      before do
        project.enabled_module_names = [permission.project_module]

        role.add_permission! permission.name
        member.save!
      end

      it 'should return the user' do
        expect(described_class.query(permission.name, project)).to eq [user]
      end
    end

    context 'w/ the user being member in the project
             w/ asking for a certain permission
             w/ the user having the permission in the project
             w/o the project being active' do
      before do
        role.add_permission! action
        member.save!

        project.update_attribute(:status, Project::STATUS_ARCHIVED)
      end

      it 'should be empty' do
        expect(described_class.query(action, project)).to eq []
      end
    end
  end
end
