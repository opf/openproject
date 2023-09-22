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
  let(:wp_role) { build(:work_package_role) }
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

  shared_examples_for 'when inquiring for project' do
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

        context 'with the user being a member of a single work package inside the project' do
          before do
            work_package.save!
            wp_member.save!
          end

          context 'with the role granting the permission' do
            before do
              wp_role.add_permission!(permission)
            end

            it { expect(user).not_to be_allowed_to(permission, project) }
          end
        end

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

        context 'and the permission being assigned to the non-member role' do
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

  shared_examples_for 'when inquiring globally' do
    let(:permission) { :add_work_packages }

    context 'when the user is an admin' do
      before { user.update(admin: true) }

      it { expect(user).to be_allowed_to(permission, nil, global: true) }
    end

    context 'when the non-member role has the permission' do
      before do
        Role.non_member.add_permission! permission
      end

      it { expect(user).to be_allowed_to(permission, nil, global: true) }
    end

    context 'when there is a global role giving the permission' do
      before { global_role.save! }

      context 'without the user having the role assigned' do
        it { expect(user).not_to be_allowed_to(global_permission.name, nil, global: true) }
      end

      context 'with the user having the role assigned' do
        before { global_member.save! }

        context 'with the role having the global permission' do
          it { expect(user).to be_allowed_to(global_permission.name, nil, global: true) }
        end

        context 'without the role having the global permission' do
          before do
            global_role.remove_permission!(global_permission.name)
          end

          it { expect(user).not_to be_allowed_to(global_permission.name, nil, global: true) }
        end
      end
    end

    context 'when the user is member of a project' do
      before { member.save }

      context 'and a project permission is requested globally' do
        context 'without the permission being assigned to the role' do
          it { expect(user).not_to be_allowed_to(permission, nil, global: true) }
        end

        # TODO: Ask somebody why this is supposed to work!?
        context 'with the permissio being assigned to the role' do
          before do
            role.add_permission! permission
          end

          it { expect(user).to be_allowed_to(permission, nil, global: true) }
        end
      end

      context 'when requesting a controller and action allowed by multiple permissions' do
        let(:permission) { :manage_categories }

        context 'without the role having the permission' do
          before { role.remove_permission!(permission) }

          it do
            expect(user)
              .not_to be_allowed_to({ controller: '/projects/settings/categories', action: 'show' }, nil, global: true)
          end

          context 'with the non-member having the permission' do
            before do
              Role.non_member.add_permission! permission
            end

            it do
              expect(user)
                .to be_allowed_to({ controller: '/projects/settings/categories', action: 'show' }, nil, global: true)
            end
          end
        end
      end
    end

    context 'when the user is anonymous' do
      context 'with the anonymous role having the permission allowed' do
        before do
          anonymous_role.add_permission! permission
        end

        it { expect(anonymous).to be_allowed_to(permission, nil, global: true) }
      end

      context 'without the anonymous role having the permission allowed' do
        it { expect(anonymous).not_to be_allowed_to(permission, nil, global: true) }
      end
    end
  end

  shared_examples_for 'when inquiring for work_package' do
    let(:permission) { :view_work_packages }
    before do
      project.save!
      work_package.save!
    end

    context 'with the user being a member of the work package' do
      before do
        wp_member.save!
      end

      context 'with the role granting the permission' do
        before do
          wp_role.add_permission!(permission)
        end

        it { expect(user).to be_allowed_to(permission, work_package) }
      end

      context 'without the role granting the permission' do
        it { expect(user).not_to be_allowed_to(permission, work_package) }

        context 'with a membership on the project granting the permission' do
          before do
            role.save!
            member.save!
            role.add_permission!(permission)
          end

          it { expect(user).to be_allowed_to(permission, work_package) }
        end
      end
    end

    context 'without the user being a member of the work package' do
      context 'with the user being a member of the project the work package belongs to' do
        before do
          member.save!
        end

        context 'and the project role does not grant the permission' do
          it { expect(user).not_to be_allowed_to(permission, work_package) }
        end

        context 'and the project role grants the permission' do
          before do
            role.add_permission!(permission)
          end

          it { expect(user).to be_allowed_to(permission, work_package) }
        end
      end

      context 'with the user being a member of another project where the role grants the permission' do
        before do
          role.save!
          member2.save!
          role.add_permission!(permission)
        end

        it { expect(user).not_to be_allowed_to(permission, work_package) }
      end
    end
  end

  context 'without preloaded permissions' do
    it_behaves_like 'when inquiring for project'
    it_behaves_like 'when inquiring globally'
    it_behaves_like 'when inquiring for work_package'
  end

  context 'with preloaded permissions' do
    it_behaves_like 'when inquiring for project' do
      let(:final_setup_step) do
        user.preload_projects_allowed_to(permission)
      end
    end
  end
end
