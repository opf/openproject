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

require "rails_helper"

RSpec.describe SquashTMIntegration::WorkPackageTab::RequirementComponent, type: :component do
  let(:work_package) { build_stubbed(:work_package) }
  let(:work_package_link) { build_stubbed(:squashtm_work_package_link, work_package:) }
  let(:requirement) do
    SquashTMIntegration::RequirementLoader::Requirement.new(
      id: 11, name: "Users can sign in", reference: "REQ-001", status:, test_cases: []
    )
  end
  let(:view_model) do
    instance_double(SquashTMIntegration::WorkPackageSquashTMTabViewModel,
                    client: SquashTMIntegration::Client.for(build_stubbed(:squashtm_server)), work_package_link:,
                    work_package:, project: work_package.project, can_manage_links?: false)
  end
  let(:status) { "APPROVED" }

  subject(:rendered) { render_inline(described_class.new(view_model, requirement:)) }

  {
    "WORK_IN_PROGRESS" => ["Work in progress", "attention"],
    "UNDER_REVIEW" => ["Under review", "accent"],
    "APPROVED" => ["Approved", "success"],
    "OBSOLETE" => ["Obsolete", "secondary"],
    "UNKNOWN_STATUS" => ["Unknown status", "secondary"]
  }.each do |squashtm_status, (text, scheme)|
    context "with the requirement status #{squashtm_status}" do
      let(:status) { squashtm_status }

      it "renders a #{scheme} label" do
        expect(rendered).to have_css(".Label--#{scheme}", text:)
      end
    end
  end
end
