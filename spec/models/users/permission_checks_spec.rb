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

RSpec.describe User, "permission check methods" do
  subject { build_stubbed(:user) }

  let(:project) { build_stubbed(:project) }

  describe ".allowed" do
    it "calls the Authorization.users method" do
      expect(Authorization).to receive(:users).with(:view_work_packages, project)
      described_class.allowed(:view_work_packages, project)
    end
  end

  it { is_expected.to delegate_method(:allowed_globally?).to(:user_permissible_service) }
  it { is_expected.to delegate_method(:allowed_in_project?).to(:user_permissible_service) }
  it { is_expected.to delegate_method(:allowed_in_any_project?).to(:user_permissible_service) }
  it { is_expected.to delegate_method(:allowed_in_entity?).to(:user_permissible_service) }
  it { is_expected.to delegate_method(:allowed_in_any_entity?).to(:user_permissible_service) }

  Member::ALLOWED_ENTITIES.each do |entity_model_name|
    context "for #{entity_model_name}" do
      let(:model_name_part) { entity_model_name.constantize.model_name.element }

      it "defines allowed_in_#{entity_model_name.underscore}?" do
        expect(subject).to respond_to("allowed_in_#{model_name_part}?")
      end

      it "defines allowed_in_any_#{entity_model_name.underscore}?" do
        expect(subject).to respond_to("allowed_in_any_#{model_name_part}?")
      end
    end
  end

  describe "#allowed_based_on_permission_context?" do
    let(:project) { nil }
    let(:entity) { nil }
    let(:result) { subject.allowed_based_on_permission_context?(permission, project:, entity:) }
    let(:permission_object) { OpenProject::AccessControl.permission(permission) }

    context "with a global permission" do
      let(:permission) { :create_user }

      it "uses the #allowed_globally? method" do
        expect(subject).to receive(:allowed_globally?).with(permission_object)
        result
      end
    end

    context "with a project permission" do
      let(:permission) { :manage_members }

      context "without a project or entity" do
        let(:entity) { nil }
        let(:project) { nil }

        it "uses the #allowed_in_any_project? method" do
          expect(subject).to receive(:allowed_in_any_project?).with(permission_object)
          result
        end
      end

      context "with a project" do
        let(:project) { build_stubbed(:project) }

        it "uses the #allowed_in_project? method" do
          expect(subject).to receive(:allowed_in_project?).with(permission_object, project)
          result
        end
      end

      context "with an entity that responds to #project" do
        let(:permission) { :manage_members }
        let(:entity) { build_stubbed(:meeting) }

        it "uses the #allowed_in_project? method" do
          expect(subject).to receive(:allowed_in_project?).with(permission_object, entity.project)
          result
        end

        context "with the project being nil" do
          let(:entity) { build_stubbed(:meeting, project: nil) }

          it "uses the #allowed_in_any_project? method" do
            expect(subject).to receive(:allowed_in_any_project?).with(permission_object)
            result
          end
        end
      end

      context "and an entity that does not respond to #project" do
        let(:entity) { build_stubbed(:user) }

        it "uses the #allowed_in_any_project? method" do
          expect(subject).to receive(:allowed_in_any_project?).with(permission_object)
          result
        end
      end
    end

    context "with a work package (and a project) permission" do
      let(:permission) { :log_own_time }

      context "with a work package as the entity" do
        let(:entity) { build_stubbed(:work_package) }

        it "uses the #allowed_in_work_package? method" do
          expect(subject).to receive(:allowed_in_work_package?).with(permission_object, entity)
          result
        end
      end

      context "with a not-persisted work package as the entity" do
        context "with a project" do
          let(:entity) { build(:work_package) }

          it "uses the #allowed_in_any_work_package? method with in_project: param" do
            expect(subject).to receive(:allowed_in_any_work_package?).with(permission_object, in_project: entity.project)
            result
          end
        end
      end

      context "with a project and no entity" do
        let(:project) { build_stubbed(:project) }

        it "uses the #allowed_in_any_work_package? method with in_project: param" do
          expect(subject).to receive(:allowed_in_any_work_package?).with(permission_object, in_project: project)
          result
        end
      end

      context "with a work package and a project" do
        let(:permission) { :log_own_time }
        let(:entity) { build_stubbed(:work_package) }
        let(:project) { build_stubbed(:project) }

        it "uses the #allowed_in_work_package? method" do
          expect(subject).to receive(:allowed_in_work_package?).with(permission_object, entity)
          result
        end
      end
    end
  end

  describe "#all_permissions_for" do
    let(:project) { create(:project) }
    let!(:other_project) { create(:project, public: true) }

    let!(:non_member) { create(:non_member, permissions: %i[view_work_packages manage_members]) }

    let(:public_permissions) { OpenProject::AccessControl.public_permissions.map(&:name) }

    context "for a non admin user" do
      subject do
        create(:user, global_permissions: [:create_user],
                      member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
      end

      it "returns all permissions given on the project" do
        expect(subject.all_permissions_for(project))
          .to match_array(%i[view_work_packages edit_work_packages] + public_permissions)
      end

      it "returns non-member permissions given on the project the user is not a member of" do
        expect(subject.all_permissions_for(other_project)).to match_array(%i[view_work_packages
                                                                             manage_members] + public_permissions)
      end

      it "returns all global permissions" do
        skip "Current implementation of the Authorization.roles query returns ALL permissions the user has, " \
             "not only global ones. We should change this in the future, that's why this test is already in here."

        expect(subject.all_permissions_for(nil)).to match_array(%i[create_user])
      end

      it "returns all permissions the user has (with project and global permissions)" do
        expect(subject.all_permissions_for(nil)).to match_array(%i[create_user
                                                                   view_work_packages edit_work_packages
                                                                   manage_members] + public_permissions)
      end
    end

    context "for an admin user" do
      subject do
        create(:admin)
      end

      it "returns all permissions given on the project" do
        expect(subject.all_permissions_for(project))
          .to include(:view_work_packages, :edit_work_packages, *public_permissions)
      end

      it "returns all permissions given globally" do
        expect(subject.all_permissions_for(nil))
          .to include(:create_user)
      end

      it "returns all permissions given on a work package" do
        expect(subject.all_permissions_for(WorkPackage.new))
          .to include(:view_work_packages, :edit_work_packages)
      end
    end
  end

  describe "#access_to?" do
    let(:project) { create(:project) }
    let(:another_project) { create(:project) }

    context "when the user is a member of the project" do
      subject { create(:user, member_with_permissions: { project => [:view_project] }) }

      it "returns true" do
        expect(subject.access_to?(project)).to be true
      end

      it "returns false for another project" do
        expect(subject.access_to?(another_project)).to be false
      end
    end

    context "when the user is not a member of the project" do
      subject { create(:user, member_with_permissions: { another_project => [:view_work_packages] }) }

      it "returns false" do
        expect(subject.access_to?(project)).to be false
      end
    end

    context "when the user is member of a work package within the project" do
      let(:work_package) { create(:work_package, project:) }

      subject { create(:user, member_with_permissions: { work_package => [:view_work_packages] }) }

      it "returns false" do
        expect(subject.access_to?(project)).to be true
      end
    end

    context "when the user is an admin" do
      subject { create(:admin) }

      it "returns true" do
        expect(subject.access_to?(project)).to be true
      end
    end
  end
end
