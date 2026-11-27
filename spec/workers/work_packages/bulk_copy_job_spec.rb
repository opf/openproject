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

RSpec.describe WorkPackages::BulkCopyJob do
  shared_let(:type) { create(:type) }
  shared_let(:other_type) { create(:type) }
  shared_let(:source) { create(:private_project, types: [type]) }
  shared_let(:role) do
    create(:project_role, permissions: %i[view_work_packages add_work_packages copy_work_packages])
  end
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package, project: source, type:) }

  # login_as is deliberately not used: it stubs the current user in the
  # RequestStore, which the job clears before it runs.
  subject(:result) do
    described_class.perform_now(user:,
                                work_package_ids: [work_package.id],
                                project: source,
                                target_project: target,
                                params: { project_id: target.id },
                                follow: true)
  end

  before do
    create(:member, project: source, principal: user, roles: [role])
    create(:member, project: target, principal: user, roles: [role])
  end

  context "when copying into a private project that accepts the work package" do
    let(:target) { create(:private_project, types: [type]) }

    it "copies the work package and redirects to the copy" do
      expect(result).to be_success

      copy = WorkPackage.find_by!(project: target)
      expect(result.result).to eq(Rails.application.routes.url_helpers.work_package_path(copy))
    end
  end

  context "when copying into a private project that rejects the work package" do
    let(:target) { create(:private_project, types: [other_type]) }

    it "fails with an error message that links to the source work package" do
      expect(result).to be_failure
      expect(result.message).to include(%(href="/work_packages/#{work_package.id}"))
    end
  end
end
