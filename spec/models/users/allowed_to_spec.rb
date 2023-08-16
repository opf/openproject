#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

RSpec.describe User, 'allowed_to?' do
  let(:user) { build(:user) }
  let(:anonymous) { build(:anonymous) }
  let(:project) { build(:project, public: false) }
  let(:project2) { build(:project, public: false) }
  let(:work_package) { build(:work_package, project:) }
  let(:role) { build(:role) }
  let(:role2) { build(:role) }
  let(:wp_role) { build(:role) }
  let(:wp_member) { build(:member, project:, entity: work_package, roles: [wp_role], principal: user) }
  let(:anonymous_role) { build(:anonymous_role) }
  let(:member) { build(:member, project:, roles: [role], principal: user) }
  let(:member2) { build(:member, project: project2, roles: [role2], principal: user) }
  let(:global_permission) { OpenProject::AccessControl.permissions.find(&:global?) }
  let(:global_role) { build(:global_role, permissions: [global_permission.name]) }
  let(:global_member) { build(:global_member, principal: user, roles: [global_role]) }

  before do
    anonymous_role.save!
    Role.non_member
    user.save!
  end

  shared_examples_for 'w/ inquiring for project' do
    let(:permission) { :add_work_packages }
    let(:final_setup_step) {}

    before do
      project.save
    end

    context 'with the user being admin' do
      before { user.update(admin: true) }

      context 'with the project being persisted and active' do
        before do
          project.save

          final_setup_step
        end

        it { expect(user).to be_allowed_to(permission, project) }
      end

      context 'with the project being archived' do
        before do
          project.update(active: false)

          final_setup_step
        end

        it { expect(user).not_to be_allowed_to(permission, project) }
      end

      context 'with the required module being inactive' do
        let(:permission) { :create_meetings } # pick a permission from a module

        before do
          project.enabled_module_names -= ['meetings']

          final_setup_step
        end

        it { expect(user).not_to be_allowed_to(permission, project) }
      end

      context 'with the permission not being automatically granted to admins' do
        let(:permission) { :work_package_assigned } # permission that is not automatically granted to admins

        before do
          final_setup_step
        end

        it { expect(user).not_to be_allowed_to(permission, project) }
      end
    end

    context 'without the user being a member in the project' do
      context 'with the project being private' do
        before { project.update(public: false) }

        context 'and the permission being assigend to the non-member role' do
          before do
            non_member = Role.non_member
            non_member.add_permission! permission

            final_setup_step
          end

          it do
            expect(user).not_to be_allowed_to(permission, project)
          end
        end

        context 'and requesting a public permission' do
          let(:permission) { :view_project } # a permission defined as public

          before do
            final_setup_step
          end

          it { expect(user).not_to be_allowed_to(permission, project) }
        end
      end

      context 'and the project being public' do
        before { project.update(public: true) }

        context 'and the permission not being assigend to the non-member role' do
          before do
            non_member = Role.non_member
            non_member.remove_permission! permission

            final_setup_step
          end

          it { expect(user).not_to be_allowed_to(permission, project) }
        end

        context 'and the permission being assigend to the non-member role' do
          before do
            non_member = Role.non_member
            non_member.add_permission! permission

            final_setup_step
          end

          it do
            expect(user).to be_allowed_to(permission, project)
          end
        end

        context 'and requesting a public permission' do
          let(:permission) { :view_project } # a permission defined as public

          before do
            final_setup_step
          end

          it { expect(user).to be_allowed_to(permission, project) }
        end
      end
    end

    context 'with the user being a member in the project' do
      before { member.save! }

      context 'without the role granting the requested permission' do
        before do
          role.remove_permission!(permission)
        end

        context 'and no permissions being assigned to the non-member role' do
          before { final_setup_step }

          it { expect(user).not_to be_allowed_to(permission, project) }
        end

        context 'and the permission being assigend to the non-member role' do
          before do
            non_member = Role.non_member
            non_member.add_permission! permission

            final_setup_step
          end

          it do
            # TODO: Figure this one out. In the documentation it says:
            #
            # Surprisingly, when looking up permissions, the non member role is always factored in, even it the user
            # does have other roles within the project as well. That means that if the user has a role in a project
            # not granting "Create new work package", but the non member role is granting the permission, the user
            # will in effect have that permission.
            #
            # So, in my eyes, with the permission being granted to the non-member role, it should be allowed to do the
            # requested action.

            skip "Have to figure out why this is not working"
            expect(user).to be_allowed_to(permission, project)
          end
        end

        context 'and requesting a public permission' do
          let(:permission) { :view_project } # a permission defined as public

          before do
            project.update(public: false)
            final_setup_step
          end

          it { expect(user).to be_allowed_to(permission, project) }
        end
      end

      context 'with the role granting the requested permission' do
        let(:permission) { :view_news }

        before do
          role.add_permission!(permission)
        end

        context 'with the module being active' do
          before do
            project.enabled_module_names += ['news']

            final_setup_step
          end

          context 'and the permission being requested with the permission name' do
            it { expect(user).to be_allowed_to(permission, project) }
          end

          context 'and the permission being requested with the controller name and action' do
            it { expect(user).to be_allowed_to({ controller: 'news', action: 'show' }, project) }
          end
        end

        context 'without the module being active' do
          before do
            project.enabled_module_names -= ['news']

            final_setup_step
          end

          context 'and the permission being requested with the permission name' do
            it { expect(user).not_to be_allowed_to(permission, project) }
          end

          context 'and the permission being requested with the controller name and action' do
            it { expect(user).not_to be_allowed_to({ controller: 'news', action: 'show' }, project) }
          end
        end
      end
    end

    context 'with the user being anonymous' do
      context 'with the project being public' do
        before { project.update(public: true) }

        context 'without the anonymous role being given the permission' do
          before do
            anonymous_role.remove_permission!(permission)
            final_setup_step
          end

          it { expect(anonymous).not_to be_allowed_to(permission, project) }
        end

        context 'with the anonymous role being given the permission' do
          before do
            anonymous_role.add_permission!(permission)
            final_setup_step
          end

          it { expect(anonymous).to be_allowed_to(permission, project) }
        end

        context 'with a public permission' do
          let(:permission) { :view_project }

          before { final_setup_step }

          it { expect(anonymous).to be_allowed_to(permission, project) }
        end

        context 'with a controller and action that is allowed via multiple permissions' do
          let(:permission) { :manage_categories }

          before do
            anonymous_role.add_permission! permission
            final_setup_step
          end

          it { expect(anonymous).to be_allowed_to({ controller: '/projects/settings/categories', action: 'show' }, project) }
        end
      end
    end

    context 'when requesting permission for multiple projects' do
      context 'with the user being a member of multiple projects' do
        before do
          member.save
          member2.save
        end

        context 'with the permission being granted in both projects' do
          before do
            role.add_permission! permission
            role2.add_permission! permission

            final_setup_step
          end

          it { expect(user).to be_allowed_to(permission, [project, project2]) }
        end
      end

      context 'with the permission being granted in only one of the two projects' do
        before do
          role.add_permission! permission
          role2.remove_permission! permission

          final_setup_step
        end

        it { expect(user).not_to be_allowed_to(permission, [project, project2]) }
      end

      context 'with the user not being member of any projects, but both projects being public' do
        before do
          project.update(public: true)
          project2.update(public: true)
        end

        context 'with non-member role having the permission' do
          before do
            non_member = Role.non_member
            non_member.add_permission! permission
            final_setup_step
          end

          it { expect(user).to be_allowed_to(permission, [project, project2]) }
        end

        context 'without non-member role having the permission' do
          before do
            non_member = Role.non_member
            non_member.remove_permission! permission
            final_setup_step
          end

          it { expect(user).not_to be_allowed_to(permission, [project, project2]) }
        end
      end

      context 'with the user not being member of any projects, but one of the projects being public' do
        before do
          project.update(public: true)
          project2.update(public: false)
        end

        context 'with non-member role having the permission' do
          before do
            non_member = Role.non_member
            non_member.add_permission! permission
            final_setup_step
          end

          it { expect(user).not_to be_allowed_to(permission, [project, project2]) }
        end
      end
    end

    context 'when requesting a global permission, but with the project as a context' do
      before do
        global_member.save!
      end

      it 'is false' do
        expect(user).not_to be_allowed_to(global_permission.name, project)
      end
    end
  end

  shared_examples_for 'w/ inquiring globally' do
    let(:permission) { :add_work_packages }
    let(:final_setup_step) {}

    context 'w/ the user being admin' do
      before do
        user.admin = true
        user.save!

        final_setup_step
      end

      it 'is true' do
        expect(user).to be_allowed_to(permission, nil, global: true)
      end
    end

    context 'w/ the user being a member in a project
             w/o the role having the necessary permission' do
      before do
        member.save!

        final_setup_step
      end

      it 'is false' do
        expect(user).not_to be_allowed_to(permission, nil, global: true)
      end
    end

    context 'w/ the user being a member in the project
             w/ the role having the necessary permission' do
      before do
        role.add_permission! permission

        member.save!

        final_setup_step
      end

      it 'is true' do
        expect(user).to be_allowed_to(permission, nil, global: true)
      end
    end

    context 'w/ the user being a member in the project
             w/ inquiring for controller and action
             w/ the role having the necessary permission' do
      let(:permission) { :view_wiki_pages }

      before do
        role.add_permission! permission

        member.save!

        final_setup_step
      end

      it 'is true' do
        expect(user)
          .to be_allowed_to({ controller: 'wiki', action: 'show' }, nil, global: true)
      end
    end

    context 'w/ the user being a member in the project
             w/o the role having the necessary permission
             w/ non members having the necessary permission' do
      before do
        non_member = Role.non_member
        non_member.add_permission! permission

        member.save!

        final_setup_step
      end

      it 'is true' do
        expect(user).to be_allowed_to(permission, nil, global: true)
      end
    end

    context 'w/o the user being a member in the project
             w/ non members being allowed the action' do
      before do
        non_member = Role.non_member
        non_member.add_permission! permission

        final_setup_step
      end

      it 'is true' do
        expect(user).to be_allowed_to(permission, nil, global: true)
      end
    end

    context "w/o the user being member in a project
             w/ the user having a global role
             w/ the global role having the necessary permission" do
      before do
        global_role.save!

        global_member.save!
      end

      it 'is true' do
        expect(user).to be_allowed_to(global_permission.name, nil, global: true)
      end
    end

    context "w/o the user being member in a project
             w/ the user having a global role
             w/o the global role having the necessary permission" do
      before do
        global_role.permissions = []
        global_role.save!

        global_member.save!
      end

      it 'is false' do
        expect(user).not_to be_allowed_to(global_permission.name, nil, global: true)
      end
    end

    context "w/o the user being member in a project
             w/o the user having the global role
             w/ the global role having the necessary permission" do
      before do
        global_role.save!
      end

      it 'is false' do
        expect(user).not_to be_allowed_to(global_permission.name, nil, global: true)
      end
    end

    context 'w/ the user being anonymous
             w/ anonymous being allowed the action' do
      before do
        anonymous_role.add_permission! permission

        final_setup_step
      end

      it 'is true' do
        expect(anonymous).to be_allowed_to(permission, nil, global: true)
      end
    end

    context 'w/ requesting a controller and action allowed by multiple permissions
             w/ the user being a member in the project
             w/o the role having the necessary permission
             w/ non members having the necessary permission' do
      let(:permission) { :manage_categories }

      before do
        non_member = Role.non_member
        non_member.add_permission! permission

        member.save!

        final_setup_step
      end

      it 'is true' do
        expect(user)
          .to be_allowed_to({ controller: '/projects/settings/categories', action: 'show' }, nil, global: true)
      end
    end

    context 'w/ the user being anonymous
             w/ anonymous being not allowed the action' do
      before do
        final_setup_step
      end

      it 'is false' do
        expect(anonymous).not_to be_allowed_to(permission, nil, global: true)
      end
    end
  end

  context 'w/o preloaded permissions' do
    it_behaves_like 'w/ inquiring for project'
    it_behaves_like 'w/ inquiring globally'
  end

  context 'w/ preloaded permissions' do
    it_behaves_like 'w/ inquiring for project' do
      let(:final_setup_step) do
        user.preload_projects_allowed_to(permission)
      end
    end
  end
end
