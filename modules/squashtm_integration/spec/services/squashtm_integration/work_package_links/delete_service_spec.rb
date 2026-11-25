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

RSpec.describe SquashTMIntegration::WorkPackageLinks::DeleteService do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_squashtm manage_squashtm_requirements] })
  end

  let!(:link) do
    create(:squashtm_work_package_link, work_package:,
                                        squashtm_requirement_id: 11,
                                        squashtm_requirement_name: "Users can sign in",
                                        squashtm_requirement_reference: "REQ-001")
  end

  subject(:result) { described_class.new(user:, model: link).call }

  it "removes the link and journals the unlinked requirement on the work package" do
    expect(result).to be_success

    expect(SquashTMIntegration::WorkPackageLink).not_to exist(link.id)
    expect(work_package.journals.last.cause).to include(
      "type" => "squashtm_requirement_unlinked",
      "squashtm_requirement_id" => 11,
      "squashtm_requirement_name" => "Users can sign in",
      "squashtm_requirement_reference" => "REQ-001"
    )
  end
end
