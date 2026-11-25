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
  shared_let(:source) { create(:project, types: [type]) }
  shared_let(:target) { create(:project, types: [type]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { source => %i[view_work_packages copy_work_packages add_work_packages],
                                             target => %i[view_work_packages copy_work_packages add_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project: source, type:) }

  subject(:result) do
    described_class.perform_now(user:,
                                work_package_ids: [work_package.id],
                                project: source,
                                target_project: target,
                                params: { project_id: target.id },
                                follow: false)
  end

  context "when the copy into the target project fails" do
    before do
      create(:string_wp_custom_field, is_required: true, types: [type], is_for_all: true)
    end

    it "renders the errors linking the source work package visible to the user" do
      expect(result).to be_failure
      expect(result.message).to include(%(href="/work_packages/#{work_package.id}"))
    end
  end
end
