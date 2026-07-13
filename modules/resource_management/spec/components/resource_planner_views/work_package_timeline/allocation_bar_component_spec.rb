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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ResourcePlannerViews::WorkPackageTimeline::AllocationBarComponent, type: :component do
  shared_let(:principal) { create(:user, firstname: "Lisa", lastname: "Anderson") }

  it "shows hours and the principal avatar for a visible assigned principal" do
    allocation = build_stubbed(:resource_allocation, principal:, allocated_time: 60 * 60, principal_explicit: true)

    render_inline(described_class.new(allocation:, visible_principal_ids: Set[principal.id]))

    expect(page).to have_text("60h")
    # The name is rendered client-side by the opce-principal element; assert it
    # carries the principal rather than the (absent) server-rendered text.
    expect(page).to have_css("opce-principal")
    expect(page.find("opce-principal")["data-principal"]).to include("Lisa Anderson")
  end

  it "anonymises an assigned principal the current user may not see" do
    allocation = build_stubbed(:resource_allocation, principal:, allocated_time: 60 * 60, principal_explicit: true)

    render_inline(described_class.new(allocation:, visible_principal_ids: Set.new))

    expect(page).to have_no_text("Lisa Anderson")
    expect(page).to have_text(I18n.t("resource_management.work_package_allocations_dialog.hidden_user"))
  end

  it "shows the role label for a filter-based allocation" do
    allocation = create(:resource_allocation, :with_user_filter, allocated_time: 20 * 60)

    render_inline(described_class.new(allocation:, visible_principal_ids: Set.new))

    expect(page).to have_text("20h")
    expect(page).to have_text(allocation.filter_name)
  end
end
