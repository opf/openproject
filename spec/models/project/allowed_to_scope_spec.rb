#-- encoding: UTF-8
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

describe Project, 'allowed to', type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:anonymous) { FactoryGirl.build(:anonymous) }
  let(:admin) { FactoryGirl.build(:admin) }

  let(:private_project) do
    FactoryGirl.build(:project,
                      is_public: false,
                      status: project_status)
  end
  let(:public_project) do
    FactoryGirl.build(:project,
                      is_public: true,
                      status: project_status)
  end
  let(:project_status) { Project::STATUS_ACTIVE }

  let(:role) do
    FactoryGirl.build(:role,
                      permissions: permissions)
  end
  let(:anonymous_role) do
    FactoryGirl.build(:anonymous_role,
                      permissions: anonymous_permissions)
  end
  let(:non_member_role) do
    FactoryGirl.build(:non_member,
                      permissions: non_member_permissions)
  end
  let(:permissions) { [action] }
  let(:anonymous_permissions) { [action] }
  let(:non_member_permissions) { [action] }
  let(:action) { :view_work_packages }
  let(:public_action) { :view_news }
  let(:public_non_module_action) { :view_project }
  let(:member) do
    FactoryGirl.build(:member,
                      user: user,
                      roles: [role],
                      project: project)
  end

  shared_examples_for 'includes the project' do
    it 'includes the project' do
      expect(Project.allowed_to(user, action)).to match_array [project]
    end
  end

  shared_examples_for 'is empty' do
    it 'is empty' do
      expect(Project.allowed_to(user, action)).to be_empty
    end
  end

  shared_examples_for 'member based allowed to check' do
    before do
      project.save!
      user.save!
    end

    context 'w/ the user being member
             w/ the role having the permission' do
      before do
        non_member_role.save!
        member.save!
      end

      it_behaves_like 'includes the project'
    end

    context 'w/ the user being member
             w/ the role having the permission
             w/o the project being active' do
      let(:project_status) { Project::STATUS_ARCHIVED }

      before do
        member.save!
      end

      it_behaves_like 'is empty'
    end

    context 'w/ the user being member
             w/o the role having the permission' do
      let(:permissions) { [] }

      before do
        member.save!
      end

      it_behaves_like 'is empty'
    end

    context 'w/o the user being member
             w/ the role having the permission' do
      it_behaves_like 'is empty'
    end

    context 'w/ the user being member
             w/ the role having the permission
             w/o the associated module being active' do
      before do
        member.save!
        project.enabled_modules = []
      end

      it_behaves_like 'is empty'
    end

    context 'w/ the user being member
             w/ the permission being public' do
      before do
        member.save!
      end

      it 'includes the project' do
        expect(Project.allowed_to(user, public_action)).to match_array [project]
      end
    end

    context 'w/ the user being member
             w/ the permission being public
             w/o the associated module being active' do
      before do
        member.save!
        project.enabled_modules = []
      end

      it 'is empty' do
        expect(Project.allowed_to(user, public_action)).to be_empty
      end
    end

    context 'w/ the user being member
             w/ the permission being public and not module bound
             w/ no module bing active' do
      before do
        member.save!
        project.enabled_modules = []
      end

      it 'includes the project' do
        expect(Project.allowed_to(user, public_non_module_action)).to match_array [project]
      end
    end
  end

  shared_examples_for 'w/ an admin user' do
    let(:user) { admin }

    before do
      project.save!
      user.save!
    end

    context 'w/o the user being a member' do
      it_behaves_like 'includes the project'
    end

    context 'w/o the project being active' do
      let(:project_status) { Project::STATUS_ARCHIVED }

      it_behaves_like 'is empty'
    end

    context 'w/o the project being active
             w/ the permission being public' do
      let(:project_status) { Project::STATUS_ARCHIVED }

      it 'is empty' do
        expect(Project.allowed_to(user, public_action)).to be_empty
      end
    end

    context 'w/o the project module being active' do
      before do
        project.enabled_modules = []
      end

      it_behaves_like 'is empty'
    end
  end

  context 'w/ the project being private' do
    let(:project) { private_project }

    it_behaves_like 'member based allowed to check'
    it_behaves_like 'w/ an admin user'

    context 'w/ the user not being logged in' do
      before do
        project.save!
        anonymous.save!
        anonymous_role.save!
      end

      context 'w/ the anonymous role having the permission' do
        it 'is empty' do
          expect(Project.allowed_to(anonymous, action)).to be_empty
        end
      end

      context 'w/ the permission being public' do
        it 'is empty' do
          expect(Project.allowed_to(anonymous, public_action)).to be_empty
        end
      end
    end
  end

  context 'w/ the project being public' do
    let(:project) { public_project }

    it_behaves_like 'member based allowed to check'
    it_behaves_like 'w/ an admin user'

    context 'w/ the user not being logged in' do
      before do
        project.save!
        anonymous.save!
        anonymous_role.save!
      end

      context 'w/ the anonymous role having the permission' do
        it 'includes the project' do
          expect(Project.allowed_to(anonymous, action)).to match_array [project]
        end
      end

      context 'w/ the anonymous role having the permission
               w/o the project being active' do
        let(:project_status) { Project::STATUS_ARCHIVED }

        it 'is empty' do
          expect(Project.allowed_to(anonymous, action)).to be_empty
        end
      end

      context 'w/o the anonymous role having the permission' do
        let(:anonymous_permissions) { [] }

        it 'is empty' do
          expect(Project.allowed_to(anonymous, action)).to be_empty
        end
      end

      context 'w/ the permission being public' do
        it 'includes the project' do
          expect(Project.allowed_to(anonymous, public_action)).to match_array [project]
        end
      end

      context 'w/ the permission being public
               w/ the associated module not being active' do
        before do
          project.enabled_modules = []
        end

        it 'is empty' do
          expect(Project.allowed_to(anonymous, public_action)).to be_empty
        end
      end

      context 'w/ the permission being public and not module bound
               w/ no module being active' do
        before do
          project.enabled_modules = []
        end

        it 'includes the project' do
          expect(Project.allowed_to(anonymous, public_non_module_action)).to match_array [project]
        end
      end
    end

    context 'w/ the user being member' do
      before do
        project.save!
        user.save!
        non_member_role.save!
        member.save!
      end

      context 'w/ the role not having the permission
               w/ non member having the permission' do
        let(:permissions) { [] }
        let(:non_member_permissions) { [action] }

        it_behaves_like 'is empty'
      end
    end

    context 'w/o the user being member' do
      before do
        project.save!
        user.save!
        non_member_role.save!
      end

      context 'w/ the non member role having the permission' do
        it_behaves_like 'includes the project'
      end

      context 'w/ the non member role having the permission
               w/o the project being active' do
        let(:project_status) { Project::STATUS_ARCHIVED }

        it_behaves_like 'is empty'
      end

      context 'w/ the permission being public and not module bound
               w/o the project being active' do
        let(:project_status) { Project::STATUS_ARCHIVED }

        it 'is empty' do
          expect(Project.allowed_to(user, public_non_module_action)).to be_empty
        end
      end

      context 'w/o the non member role having the permission' do
        let(:non_member_permissions) { [] }

        it_behaves_like 'is empty'
      end

      context 'w/ the permission being public' do
        it 'includes the project' do
          expect(Project.allowed_to(user, public_action)).to match_array [project]
        end
      end

      context 'w/ the permission being public
               w/ the module not being active' do
        before do
          project.enabled_modules = []
        end

        it 'is empty' do
          expect(Project.allowed_to(user, public_action)).to be_empty
        end
      end

      context 'w/ the permission being public and not module bound
               w/ no module active' do
        before do
          project.enabled_modules = []
        end

        it 'includes the project' do
          expect(Project.allowed_to(user, public_non_module_action)).to match_array [project]
        end
      end
    end
  end
end
