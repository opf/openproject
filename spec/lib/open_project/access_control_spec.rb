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

RSpec.describe OpenProject::AccessControl do
  def setup_permissions
    OpenProject::AccessControl.map do |map|
      map.permission :no_module_project_permission_with_contract_actions,
                     { dont: :care },
                     permissible_on: :project,
                     require: :member,
                     contract_actions: { foo: :create }
      map.permission :no_module_global_permission,
                     { dont: :care },
                     permissible_on: :global
      map.permission :no_module_project_permission,
                     { dont: :care },
                     permissible_on: :project
      map.permission :no_module_work_package_permission,
                     { dont: :care },
                     permissible_on: :work_package
      map.permission :no_module_mixed_permissible_on_permission,
                     { dont: :care },
                     permissible_on: %i[project work_package]

      map.project_module :global_module do |mod|
        mod.permission :global_module_global_permission,
                       { dont: :care },
                       permissible_on: :global
      end

      map.project_module :project_module do |mod|
        mod.permission :project_module_project_permission_with_contract_actions,
                       { dont: :care },
                       permissible_on: :project,
                       contract_actions: { bar: %i[create read] },
                       public: true

        mod.permission :project_module_project_permission,
                       { dont: :care },
                       permissible_on: :project
      end

      map.project_module :mixed_module do |mod|
        mod.permission :mixed_module_project_permission_granted_to_admin,
                       { dont: :care },
                       permissible_on: :project,
                       grant_to_admin: true
        mod.permission :mixed_module_global_permission_with_contract_actions,
                       { dont: :care },
                       permissible_on: :global,
                       contract_actions: { baz: %i[destroy] }
      end

      map.project_module :dependent_module, dependencies: :project_module do |mod|
        mod.permission :dependent_module_project_permission_not_granted_to_admin,
                       { dont: :care },
                       permissible_on: :project,
                       grant_to_admin: false
      end
    end
  end

  describe ".disable_modules_permissions" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    RSpec::Matchers.define :not_belong_to_project_module do |project_module|
      match do |actual|
        actual.project_module != project_module
      end
    end

    subject do
      described_class.disable_modules_permissions(:project_module)
      described_class
    end

    it "removes from permissions" do
      expect(subject.permissions)
        .to all(not_belong_to_project_module(:project_module))
    end

    it "removes from global permissions" do
      expect(subject.global_permissions)
        .to all(not_belong_to_project_module(:project_module))
    end

    it "removes from public permissions" do
      expect(subject.public_permissions)
        .to all(not_belong_to_project_module(:project_module))
    end

    it "removes from members-only permissions" do
      expect(subject.members_only_permissions)
        .to all(not_belong_to_project_module(:project_module))
    end

    it "removes from loggedin-only permissions" do
      expect(subject.loggedin_only_permissions)
        .to all(not_belong_to_project_module(:project_module))
    end

    it "disables repository module" do
      expect(subject.available_project_modules)
        .not_to include(:project_module)
    end

    it "lists the permissions in the disabled_permissions" do
      expect(subject.disabled_permissions.map(&:name))
        .to include :project_module_project_permission_with_contract_actions,
                    :project_module_project_permission
    end

    it "returns true on disabled_permission?" do
      expect(subject.disabled_permission?(:project_module_project_permission))
        .to be true
    end
  end

  describe ".permissions" do
    subject(:permissions) { described_class.permissions }

    it "returns an array permissions" do
      expect(permissions)
        .to all(be_instance_of(OpenProject::AccessControl::Permission))
    end

    it "returns only enabled permissions" do
      expect(permissions)
        .to all(be_enabled)
    end
  end

  describe ".permission" do
    context "for a project module permission" do
      subject { described_class.permission(:view_work_packages) }

      it "is a permission" do
        expect(subject)
          .to be_a(OpenProject::AccessControl::Permission)
      end

      it "is the permission with the queried-for name" do
        expect(subject.name)
          .to eq(:view_work_packages)
      end

      it "belongs to a project module" do
        expect(subject.project_module)
          .to eq(:work_package_tracking)
      end
    end

    context "for a non module permission" do
      subject { described_class.permission(:edit_project) }

      it "is a permission" do
        expect(subject)
          .to be_a(OpenProject::AccessControl::Permission)
      end

      it "is the permission with the queried-for name" do
        expect(subject.name)
          .to eq(:edit_project)
      end

      it "does not belong to a project module" do
        expect(subject.project_module)
          .to be_nil
      end

      it "includes actions" do
        expect(subject.controller_actions)
          .to include("projects/settings/general/show")
      end
    end

    describe "#dependencies" do
      context "for a permission with a pre-requisite" do
        subject(:dependencies) do
          described_class.permission(:edit_work_packages)
                         .dependencies
        end

        it "denotes the pre-requisites" do
          expect(dependencies)
            .to contain_exactly(:view_work_packages)
        end
      end

      context "for a permission without a pre-requisite" do
        subject(:dependencies) do
          described_class.permission(:view_work_packages)
                         .dependencies
        end

        it "denotes no pre-requisites" do
          expect(dependencies)
            .to be_empty
        end
      end
    end
  end

  describe ".modules" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:dependencies) do
      described_class.modules
                     .find { _1[:name] == :dependent_module }[:dependencies]
    end

    it "can store specified dependencies" do
      expect(dependencies)
        .to contain_exactly(:project_module)
    end
  end

  describe ".work_package_permissions" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:work_package_permissions) do
      described_class.work_package_permissions
    end

    describe "size" do
      it { expect(work_package_permissions.size).to eq(2) }
    end

    it do
      expect(work_package_permissions.map(&:name))
        .to contain_exactly(:no_module_work_package_permission,
                            :no_module_mixed_permissible_on_permission)
    end
  end

  describe ".project_permissions" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:project_permissions) do
      described_class.project_permissions
    end

    describe "size" do
      it { expect(project_permissions.size).to eq(7) }
    end

    it do
      expect(project_permissions.map(&:name))
        .to contain_exactly(:no_module_project_permission_with_contract_actions,
                            :no_module_project_permission,
                            :project_module_project_permission_with_contract_actions,
                            :project_module_project_permission,
                            :mixed_module_project_permission_granted_to_admin,
                            :dependent_module_project_permission_not_granted_to_admin,
                            :no_module_mixed_permissible_on_permission)
    end
  end

  describe ".global_permissions" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:global_permissions) do
      described_class.global_permissions
    end

    describe "size" do
      it { expect(global_permissions.size).to eq(3) }
    end

    it do
      expect(global_permissions.map(&:name))
        .to contain_exactly(:no_module_global_permission,
                            :global_module_global_permission,
                            :mixed_module_global_permission_with_contract_actions)
    end
  end

  describe ".available_project_modules" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:available_project_modules) do
      described_class.available_project_modules
    end

    it { expect(available_project_modules).to include(:project_module, :mixed_module, :dependent_module) }
    it { expect(available_project_modules).not_to include(:global_module) }

    context "when a module specifies :if" do
      before do
        described_class.map do |map|
          map.project_module :dynamic_module, if: if_proc do |mod|
            mod.permission :perm_d1, { dont: :care }, permissible_on: :project
          end
        end
      end

      context "with if: true" do
        let(:if_proc) { ->(*) { true } }

        it "is considered available" do
          expect(available_project_modules).to include(:dynamic_module)
        end
      end

      context "with if: false" do
        let(:if_proc) { ->(*) { false } }

        it "is not considered available anymore" do
          expect(available_project_modules).not_to include(:dynamic_module)
        end
      end

      context "with if: dynamically changing" do
        let(:if_proc) { ->(*) { if_state[:available] } }
        let(:if_state) { { available: true } }

        it "reevaluates module availability each time", :aggregate_failures do
          if_state[:available] = true
          expect(described_class.available_project_modules).to include(:dynamic_module)

          if_state[:available] = false
          expect(described_class.available_project_modules).not_to include(:dynamic_module)
        end
      end
    end
  end

  describe ".contract_actions_map" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    subject(:contract_actions_map) do
      described_class.contract_actions_map
    end

    it "contains all contract actions grouped by the permission name" do
      expect(contract_actions_map)
        .to eql(mixed_module_global_permission_with_contract_actions: {
                  actions: { baz: [:destroy] },
                  global: true,
                  module_name: :mixed_module,
                  grant_to_admin: true,
                  public: false
                },
                no_module_project_permission_with_contract_actions: {
                  actions: { foo: :create },
                  global: false,
                  module_name: nil,
                  grant_to_admin: true,
                  public: false
                },
                project_module_project_permission_with_contract_actions: {
                  actions: { bar: %i[create read] },
                  global: false,
                  module_name: :project_module,
                  grant_to_admin: true,
                  public: true
                })
    end
  end

  describe ".grant_to_admin?" do
    include_context "with blank access control state"

    before do
      setup_permissions
    end

    context "without specifying whether the permission is granted to admins" do
      it "is granted" do
        expect(described_class)
          .to be_grant_to_admin(:no_module_project_permission_with_contract_actions)
      end
    end

    context "for an explicitly granted permission" do
      it "is granted" do
        expect(described_class)
          .to be_grant_to_admin(:mixed_module_project_permission_granted_to_admin)
      end
    end

    context "for an explicitly non-granted permission" do
      it "is not granted" do
        expect(described_class)
          .not_to be_grant_to_admin(:dependent_module_project_permission_not_granted_to_admin)
      end
    end

    context "for a non existing permission" do
      it "is granted" do
        expect(described_class)
          .to be_grant_to_admin(:not_existing)
      end
    end
  end

  describe ".disabled_permission?" do
    include_context "with blank access control state"

    before do
      described_class.map do |map|
        map.project_module :some_module do |mod|
          mod.permission :disabled_permission1,
                         { some: :action },
                         permissible_on: :project,
                         enabled: false

          mod.permission :disabled_permission2,
                         { some: :action,
                           another: :action },
                         permissible_on: :project,
                         enabled: -> { false }

          mod.permission :enabled_permission,
                         { another: :action },
                         permissible_on: :project
        end
      end
    end

    it "is false for enabled permissions" do
      expect(subject)
        .not_to be_disabled_permission(:enabled_permission)
    end

    it "is true for disabled permission" do
      expect(subject)
        .to be_disabled_permission(:disabled_permission1)
    end

    it "is true for action hash where permissions granting are disabled" do
      expect(subject)
        .to be_disabled_permission(controller: "some", action: "action")
    end

    it "is false for action hash where not all permissions granting are disabled (but some can)" do
      expect(subject)
        .not_to be_disabled_permission(controller: "another", action: "action")
    end

    it "is false for an unknown permission" do
      expect(subject)
        .not_to be_disabled_permission(:unknown_permission)
    end
  end
end
