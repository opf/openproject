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

RSpec.describe SquashTMIntegration::WorkPackageTab::RequirementLinkFormComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:work_package_link) { SquashTMIntegration::WorkPackageLink.new(work_package:) }
  let(:requirement_options) do
    [{ id: 1, name: "Users can sign in", reference: "REQ-001" },
     { id: 2, name: "Without reference", reference: nil }]
  end
  let(:view_model) do
    instance_double(SquashTMIntegration::WorkPackageSquashTMTabViewModel, work_package:, project:, work_package_link:)
  end

  current_user { build_stubbed(:user) }

  subject(:render_component) { render_inline(described_class.new(view_model, requirement_options:)) }

  it "offers the requirements of the linked SquashTM project" do
    render_component

    expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
    expect(page).to have_select("SquashTM requirement", with_options: ["REQ-001 – Users can sign in", "Without reference"])
    expect(page).to have_button("Link requirement")
  end

  context "when the requirements could not be loaded" do
    let(:requirement_options) { nil }

    it "explains that SquashTM is not reachable" do
      render_component

      expect(page).to have_text("The SquashTM requirements could not be loaded")
      expect(page).to have_no_button("Link requirement")
    end
  end
end
