# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Members::Scopes::Visible do
  def create_member(project:, permissions:)
    create(:member,
           project:,
           roles: [create(:project_role, permissions:)],
           principal: user)
  end

  def create_work_package_share(project:)
    create(:member,
           project:,
           roles: [work_package_role],
           entity: create(:work_package, project:),
           principal: user)
  end

  let(:user) { create(:user, admin:) }

  let(:view_members_project) { create(:project) }
  let(:manage_members_project) { create(:project) }
  let(:view_shared_work_packages_project) { create(:project) }

  let(:work_package_role) { create(:view_work_package_role) }

  let!(:view_members_member) do
    create_member(project: view_members_project, permissions: %i[view_members])
  end
  let!(:manage_members_member) do
    create_member(project: manage_members_project, permissions: %i[manage_members])
  end
  let!(:view_shared_work_packages_member) do
    create_member(project: view_shared_work_packages_project, permissions: %i[view_shared_work_packages])
  end

  let!(:view_members_work_package_share) do
    create_work_package_share(project: view_members_project)
  end
  let!(:manage_members_work_package_share) do
    create_work_package_share(project: manage_members_project)
  end
  let!(:view_shared_work_packages_work_package_share) do
    create_work_package_share(project: view_shared_work_packages_project)
  end

  describe ".visible" do
    subject { Member.visible(user) }

    context "for admin" do
      let(:admin) { true }

      it "returns all members" do
        expect(subject).to contain_exactly view_members_member,
                                           manage_members_member,
                                           view_shared_work_packages_member,
                                           view_members_work_package_share,
                                           manage_members_work_package_share,
                                           view_shared_work_packages_work_package_share
      end
    end

    context "for non admin" do
      let(:admin) { false }

      it "returns only members allowed by permissions" do
        expect(subject).to contain_exactly view_members_member,
                                           manage_members_member,
                                           view_shared_work_packages_work_package_share
      end

      context "when another work package is shared with a different user" do
        let(:other_principal) { create(:user) }
        let(:inaccessible_work_package) { create(:work_package, project: view_shared_work_packages_project) }
        let!(:share_for_other_principal) do
          create(:member,
                 project: view_shared_work_packages_project,
                 entity: inaccessible_work_package,
                 principal: other_principal,
                 roles: [create(:edit_work_package_role)])
        end

        it "does not display shares for work packages the user cannot view" do
          expect(subject).not_to include(share_for_other_principal)
        end

        it "still includes shares on work packages visible to the user" do
          expect(subject).to include(view_shared_work_packages_work_package_share)
        end
      end
    end
  end
end
