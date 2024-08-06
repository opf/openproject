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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Projects::ArchiveContract do
  include_context "ModelContract shared context"

  shared_let(:archivist_role) { create(:project_role, permissions: %i[archive_project]) }
  let(:project) { build_stubbed(:project) }
  let(:contract) { described_class.new(project, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "when user has archive_project permission" do
    let(:project) { create(:project) }
    let(:current_user) { create(:user, member_with_roles: { project => archivist_role }) }

    include_examples "contract is valid"
  end

  context "with subprojects" do
    shared_let(:subproject1) { create(:project) }
    shared_let(:subproject2) { create(:project) }
    shared_let(:project) { create(:project, children: [subproject1, subproject2]) }
    shared_let(:current_user) { create(:user, member_with_roles: { project => archivist_role }) }

    shared_examples "with archive_project permission on all/some/none of subprojects" do
      context "when user does not have archive_project permission on any subprojects" do
        include_examples "contract is invalid", base: :archive_permission_missing_on_subprojects
      end

      context "when user has archive_project permission on some subprojects but not all" do
        before do
          create(:member, user: current_user, project: subproject1, roles: [archivist_role])
        end

        include_examples "contract is invalid", base: :archive_permission_missing_on_subprojects
      end

      context "when user has archive_project permission on all subprojects" do
        before do
          create(:member, user: current_user, project: subproject1, roles: [archivist_role])
          create(:member, user: current_user, project: subproject2, roles: [archivist_role])
        end

        include_examples "contract is valid"
      end

      context "when some of subprojects are archived but not all" do
        before do
          subproject1.update_column(:active, false)
          create(:member, user: current_user, project: subproject2, roles: [archivist_role])
        end

        include_examples "contract is valid"
      end

      context "when all of subprojects are archived" do
        before do
          subproject1.update_column(:active, false)
          subproject2.update_column(:active, false)
        end

        include_examples "contract is valid"
      end
    end

    include_examples "contract is valid for active admins and invalid for regular users"
    include_examples "with archive_project permission on all/some/none of subprojects"

    context "with deep nesting" do
      before do
        subproject2.update(parent: subproject1)
      end

      include_examples "contract is valid for active admins and invalid for regular users"
      include_examples "with archive_project permission on all/some/none of subprojects"
    end
  end
end
