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

RSpec.describe WorkPackage, ".allowed_to" do
  shared_let(:user) { create(:user) }
  shared_let(:project_status) { true }
  shared_let(:private_project) { create(:project, public: false, active: project_status) }
  shared_let(:public_project) { create(:project, public: true, active: project_status) }

  shared_let(:work_package_in_public_project) { create(:work_package, project: public_project) }
  shared_let(:work_package_in_private_project) { create(:work_package, project: private_project) }
  shared_let(:other_work_package_in_private_project) { create(:work_package, project: private_project) }

  let(:project_permissions) { [] }
  let(:project_role) { create(:project_role, permissions: project_permissions) }

  let(:work_package_permissions) { [] }
  let(:work_package_role) { create(:work_package_role, permissions: work_package_permissions) }

  let(:anonymous_permissions) { [] }
  let(:anonymous_role) { create(:anonymous_role, permissions: anonymous_permissions) }

  let(:non_member_permissions) { [] }
  let!(:non_member_role) { create(:non_member, permissions: non_member_permissions) }

  let(:action) { project_or_work_package_action }
  let(:project_or_work_package_action) { :view_work_packages }
  let(:public_action) { :view_news }
  let(:public_non_module_action) { :view_project }
  let(:non_module_action) { :edit_project }

  context "when querying for a permission that does not exist" do
    it "raises an error" do
      expect do
        described_class.allowed_to(build(:user), :non_existing_permission)
      end.to raise_error(Authorization::UnknownPermissionError)
    end
  end

  context "when querying for a permission that does not apply to the context" do
    it "raises an error" do
      expect do
        described_class.allowed_to(build(:user), public_action)
      end.to raise_error(Authorization::IllegalPermissionContextError)
    end
  end

  context "when the user is an admin" do
    let(:user) { create(:admin) }

    subject { described_class.allowed_to(user, action) }

    it "returns all work packages" do
      expect(subject).to contain_exactly(
        work_package_in_public_project,
        work_package_in_private_project,
        other_work_package_in_private_project
      )
    end

    context "when the project is archived" do
      before do
        public_project.update!(active: false)
        private_project.update!(active: false)
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end

    context "when the user is locked" do
      before do
        user.locked!
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end

    context "when the module the permission belongs to is disabled" do
      before do
        private_project.enabled_module_names = private_project.enabled_module_names - ["work_package_tracking"]
      end

      it "excludes work packages where the module is disabled in" do
        expect(subject).to contain_exactly(work_package_in_public_project)
      end
    end
  end

  context "when the user has the permission directly on the work package" do
    let(:work_package_permissions) { [action] }

    before do
      create(:member, project: private_project, entity: work_package_in_private_project,
                      user:, roles: [work_package_role])
    end

    subject { described_class.allowed_to(user, action) }

    it "returns the authorized work package" do
      expect(subject).to contain_exactly(work_package_in_private_project)
    end

    context "when the project is archived" do
      before do
        public_project.update!(active: false)
        private_project.update!(active: false)
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end

    context "when the user is locked" do
      before do
        user.locked!
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end
  end

  context "when the user has the permission on the project the work package belongs to" do
    let(:project_permissions) { [action] }

    before do
      create(:member, project: private_project, user:, roles: [project_role])
    end

    subject { described_class.allowed_to(user, action) }

    it "returns the authorized work packages" do
      expect(subject).to contain_exactly(
        work_package_in_private_project,
        other_work_package_in_private_project
      )
    end

    context "when the project is archived" do
      before do
        public_project.update!(active: false)
        private_project.update!(active: false)
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end

    context "when the user is locked" do
      before do
        user.locked!
      end

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end
  end

  context "when the user has a different permission on the project, but the requested one on a specific work package" do
    let(:project_permissions) { [:view_work_packages] }
    let(:work_package_permissions) { %i[view_work_packages edit_work_packages] }

    before do
      create(:member, project: private_project, entity: work_package_in_private_project, user:, roles: [work_package_role])
      create(:member, project: private_project, user:, roles: [project_role])
    end

    context "and requesting a permission that is only granted on the single work package" do
      subject { described_class.allowed_to(user, :edit_work_packages) }

      it "returns the authorized work packages" do
        expect(subject).to contain_exactly(work_package_in_private_project)
      end
    end

    context "and requesting a permission that is granted on the project and the work package" do
      subject { described_class.allowed_to(user, :view_work_packages) }

      it "returns the authorized work packages" do
        expect(subject).to contain_exactly(work_package_in_private_project, other_work_package_in_private_project)
      end
    end
  end

  context "when the user is not logged in (anonymous)" do
    let(:user) { User.anonymous }
    let(:action) { :view_work_packages }

    before do
      anonymous_role.save!
    end

    subject { described_class.allowed_to(user, action) }

    context "with the anonymous role having the permission" do
      let(:anonymous_permissions) { [action] }

      it "returns work packages in the public project" do
        expect(subject).to contain_exactly(work_package_in_public_project)
      end
    end

    context "with the anonymous role lacking the permission" do
      let(:anonymous_permissions) { [] }

      it "is empty" do
        expect(subject).to be_empty
      end
    end
  end

  context "when the user isn`t member in the project" do
    let(:user) { create(:user) }
    let(:action) { :view_work_packages }

    before do
      non_member_role.save!
    end

    subject { described_class.allowed_to(user, action) }

    context "with the non member role having the permission" do
      let(:non_member_permissions) { [action] }

      it "returns work packages in the public project" do
        expect(subject).to contain_exactly(work_package_in_public_project)
      end
    end

    context "with the non member role lacking the permission" do
      let(:non_member_permissions) { [] }

      it "is empty" do
        expect(subject).to be_empty
      end
    end
  end
end
