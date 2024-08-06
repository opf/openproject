#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe User, "allowed scope" do
  let(:user) { member.principal }
  let(:anonymous) { build(:anonymous) }
  let(:project) { build(:project, public: false) }
  let(:project2) { build(:project, public: false) }
  let(:role) { build(:project_role) }
  let(:role2) { build(:project_role) }
  let(:anonymous_role) { build(:anonymous_role) }
  let(:member) do
    build(:member, project:,
                   roles: [role])
  end

  let(:action) { :view_work_packages }
  let(:other_action) { :another }
  let(:public_action) { :view_project }

  before do
    user.save!
    anonymous.save!
    ProjectRole.anonymous
    ProjectRole.non_member
  end

  context "with the context being a project " \
          "without the project being public " \
          "with the user being member in the project " \
          "with the role having the necessary permission" do
    before do
      role.add_permission! action

      member.save!
    end

    it "returns the user" do
      expect(described_class.allowed(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "without the user being member in the project " \
          "with the user being admin" do
    before do
      user.update_attribute(:admin, true)
    end

    it "returns the user" do
      expect(described_class.allowed(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "without the user being member in the project " \
          "with the user being admin " \
          "with the action not granted to admins" do
    let(:action) { :work_package_assigned }

    before do
      user.update_attribute(:admin, true)
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "with the user being member in the project " \
          "without the role having the necessary permission" do
    before do
      role.save!
      member.save!
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "without the user being member in the project " \
          "with the role having the necessary permission" do
    before do
      role.add_permission! action
    end

    it "returns the user" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "without the user being member in the project " \
          "with the user being member in a different project " \
          "with the role having the permission" do
    before do
      role.add_permission! action

      member.project = project2
      member.save!
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "without the user being member in the project " \
          "with the user being member in a different project " \
          "with the role having the permission" do
    before do
      role.add_permission! action

      project.update(public: true)

      member.project = project2
      member.save!
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "without the user being member in the project " \
          "with the non member role having the necessary permission" do
    before do
      project.public = true

      non_member = ProjectRole.non_member
      non_member.add_permission! action

      project.save!
    end

    it "returns the user" do
      expect(described_class.allowed(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "without the user being member in the project " \
          "with the anonymous role having the necessary permission" do
    before do
      project.public = true

      anonymous_role = ProjectRole.anonymous
      anonymous_role.add_permission! action

      project.save!
    end

    it "returns the anonymous user" do
      expect(described_class.allowed(action, project).where(id: [user.id, anonymous.id])).to contain_exactly(anonymous)
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "without the user being member in the project " \
          "with the non member role having another permission" do
    before do
      project.public = true

      non_member = ProjectRole.non_member
      non_member.add_permission! other_action

      project.save!
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "with the project being private " \
          "without the user being member in the project " \
          "with the non member role having the permission" do
    before do
      non_member = ProjectRole.non_member
      non_member.add_permission! action

      project.save!
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "with the user being member in the project " \
          "without the role having the necessary permission " \
          "with the non member role having the permission" do
    before do
      project.public = true
      project.save

      role.add_permission! other_action
      member.save!

      non_member = ProjectRole.non_member
      non_member.add_permission! action
    end

    it "is empty" do
      expect(described_class.allowed(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with the context being a project " \
          "without the project being public " \
          "with the user being member in the project " \
          "without the role having the permission " \
          "with the permission being public" do
    before do
      member.save!
    end

    it "returns the user" do
      expect(described_class.allowed(public_action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with the context being a project " \
          "with the project being public " \
          "without the user being member in the project " \
          "without the role having the permission " \
          "with the permission being public" do
    before do
      project.public = true
      project.save
    end

    it "returns the user and anonymous" do
      expect(described_class.allowed(public_action,
                                     project).where(id: [user.id, anonymous.id])).to contain_exactly(user, anonymous)
    end
  end

  context "with the context being a project " \
          "with the user being member in the project " \
          "with asking for a certain permission " \
          "with the permission belonging to a module " \
          "without the module being active" do
    let(:permission) do
      OpenProject::AccessControl.permissions.find { |p| p.project_module.present? }
    end

    before do
      project.enabled_module_names = []

      role.add_permission! permission.name
      member.save!
    end

    it "is empty" do
      expect(described_class.allowed(permission.name, project).where(id: user.id)).to eq []
    end
  end

  context "with the context being a project " \
          "with the user being member in the project " \
          "with asking for a certain permission " \
          "with the permission belonging to a module " \
          "with the module being active" do
    let(:permission) do
      OpenProject::AccessControl.permissions.find { |p| p.project_module.present? }
    end

    before do
      project.enabled_module_names = [permission.project_module]

      role.add_permission! permission.name
      member.save!
    end

    it "returns the user" do
      expect(described_class.allowed(permission.name, project).where(id: user.id)).to eq [user]
    end
  end

  context "with the context being a project " \
          "with the user being member in the project " \
          "with asking for a certain permission " \
          "with the user having the permission in the project " \
          "without the project being active" do
    before do
      role.add_permission! action
      member.save!

      project.update(active: false)
    end

    it "is empty" do
      expect(described_class.allowed(action, project)).to eq []
    end
  end

  context "with only asking for members " \
          "without the project being public " \
          "with the user being member in the project " \
          "with the role having the necessary permission" do
    before do
      role.add_permission! action

      member.save!
    end

    it "returns the user" do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with only asking for members " \
          "without the project being public " \
          "without the user being member in the project " \
          "with the user being admin" do
    before do
      user.update_attribute(:admin, true)
    end

    it "returns the user" do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to be_empty
    end
  end

  context "with only asking for members " \
          "with the project being public " \
          "with the user being member in the project " \
          "with the role having the necessary permission" do
    before do
      project.update_attribute(:public, true)

      role.add_permission! action

      member.save!
    end

    it "returns the user" do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to contain_exactly(user)
    end
  end

  context "with only asking for members " \
          "with the project being public " \
          "without the user being member in the project " \
          "with the role having the necessary permission" do
    before do
      project.update_attribute(:public, true)

      role.add_permission! action
    end

    it "returns the user" do
      expect(described_class.allowed_members(action, project).where(id: user.id)).to be_empty
    end
  end

  describe ".allowed_members_on_work_package" do
    shared_let(:richard)  { create(:user) }
    shared_let(:dinesh)   { create(:user) }
    shared_let(:gilfoyle) { create(:user) }
    shared_let(:gavin)    { create(:user) }
    shared_let(:erlich)   { create(:user) }
    shared_let(:jared)    { create(:user) }

    shared_let(:project)       { create(:project) }
    shared_let(:other_project) { create(:project) }

    shared_let(:work_package)       { create(:work_package, project:) }
    shared_let(:other_work_package) { create(:work_package, project: other_project) }

    shared_let(:allowed_work_package_role)     { create(:work_package_role, permissions: %i[view_work_packages]) }
    shared_let(:non_allowed_work_package_role) { create(:work_package_role, permissions: []) }

    shared_let(:allowed_project_role)     { create(:project_role, permissions: %i[view_work_packages]) }
    shared_let(:non_allowed_project_role) { create(:project_role, permissions: []) }

    before_all do
      create(:work_package_member,
             principal: richard, entity: work_package, roles: [allowed_work_package_role])
      create(:work_package_member,
             principal: dinesh, entity: work_package, roles: [non_allowed_work_package_role])
      create(:work_package_member,
             principal: gilfoyle, entity: other_work_package, roles: [allowed_work_package_role])

      create(:member, principal: gavin, project:, roles: [allowed_project_role])
      create(:member, principal: erlich, project:, roles: [non_allowed_project_role])
      create(:member, principal: jared, project: other_project, roles: [allowed_project_role])
    end

    it "returns members of the work package and the work package's project with the given permission" do
      expect(described_class.allowed_members_on_work_package(action, work_package))
        .to contain_exactly(richard, gavin)
    end
  end
end
