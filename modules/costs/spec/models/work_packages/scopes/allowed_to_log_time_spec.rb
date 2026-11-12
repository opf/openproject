# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Scopes::AllowedToLogTime do
  shared_let(:non_admin) { create(:user) }
  shared_let(:admin) { create(:admin) }
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

  let(:non_member_permissions) { [] }
  let!(:non_member_role) { create(:non_member, permissions: non_member_permissions) }

  let(:action) { project_or_work_package_action }
  let(:project_or_work_package_action) { :log_own_time }

  subject { WorkPackage.allowed_to_log_time(user) }

  context "when the user is an admin" do
    let(:user) { admin }

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

    context "when the costs module is disabled" do
      before do
        private_project.enabled_module_names = private_project.enabled_module_names - ["costs"]
      end

      it "excludes work packages where the module is disabled in" do
        expect(subject).to contain_exactly(work_package_in_public_project)
      end
    end
  end

  context "when the user is a non admin, logged in user" do
    let(:user) { non_admin }

    context "when the user has log_own_time permission directly on the work package" do
      let(:work_package_permissions) { [:log_own_time] }

      before do
        create(:member,
               project: private_project,
               entity: work_package_in_private_project,
               user:,
               roles: [work_package_role])
      end

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

      context "when the module is inactive in the project" do
        before do
          public_project.enabled_modules = []
          private_project.enabled_modules = []
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

    context "when the user has the log_own_time permission on the project the work package belongs to" do
      let(:project_permissions) { [:log_own_time] }

      before do
        create(:member,
               project: private_project,
               user:,
               roles: [project_role])
      end

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

      context "when the module is inactive in the project" do
        before do
          public_project.enabled_modules = []
          private_project.enabled_modules = []
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

    context "when the user has the log_time permission on the project the work package belongs to" do
      let(:project_permissions) { [:log_time] }

      before do
        create(:member,
               project: private_project,
               user:,
               roles: [project_role])
      end

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

      context "when the module is inactive in the project" do
        before do
          public_project.enabled_modules = []
          private_project.enabled_modules = []
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

    context "when the user has a different permission on the project, but log_own_time on a specific work package" do
      let(:project_permissions) { [:view_work_packages] }
      let(:work_package_permissions) { %i[log_own_time] }

      before do
        create(:member, project: private_project, entity: work_package_in_private_project, user:, roles: [work_package_role])
        create(:member, project: private_project, user:, roles: [project_role])
      end

      it "returns the authorized work packages" do
        expect(subject).to contain_exactly(
          work_package_in_private_project
        )
      end
    end

    context "when the user isn`t member in the project" do
      before do
        non_member_role.save!
      end

      context "with the non member role having the permission" do
        let(:non_member_permissions) { [:log_own_time] }

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
end
