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
require_relative "../../support/pages/backlog"

# Selenium, not Cuprite: batch selection is driven through modifier clicks,
# and the DnD engine needs real browser drag events.
RSpec.describe "Backlogs batch move", :js, :selenium, :settings_reset do
  include RSpec::Wait

  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints manage_sprint_items view_work_packages edit_work_packages))
  end

  let!(:sprint) { create(:sprint, project:) }
  let!(:sprint_wp1) { create(:work_package, sprint:, position: 1, type:, project:) }
  let!(:sprint_wp2) { create(:work_package, sprint:, position: 2, type:, project:) }
  let!(:sprint_wp3) { create(:work_package, sprint:, position: 3, type:, project:) }
  let!(:bucket) { create(:backlog_bucket, project:, name: "Backlog bucket") }
  let!(:bucket_wp1) { create(:work_package, backlog_bucket: bucket, position: 1, type:, project:) }
  let!(:bucket_wp2) { create(:work_package, backlog_bucket: bucket, position: 2, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "moves a sparse cross-list batch as one ordered block and clears the selection" do
    backlogs_page.toggle_card(bucket_wp2)
    backlogs_page.toggle_card(sprint_wp3)

    backlogs_page.drag_work_package(bucket_wp2, after: sprint_wp1)

    backlogs_page.expect_sprint_items_in_order(sprint, items: [sprint_wp1, bucket_wp2, sprint_wp3, sprint_wp2]
    )
    expect(backlogs_page.selected_card_ids).to be_empty
    # Poll persistence, never trust the DOM alone:
    wait_for { sprint.work_packages_for(project).pluck(:id) }
      .to eq [sprint_wp1.id, bucket_wp2.id, sprint_wp3.id, sprint_wp2.id]
  end

  it "moves an unselected card alone, replacing the batch" do
    backlogs_page.toggle_card(sprint_wp1)
    backlogs_page.toggle_card(sprint_wp2)

    backlogs_page.drag_work_package(sprint_wp3, after: bucket_wp1)

    wait_for { WorkPackage.where(backlog_bucket: bucket).order(:position).pluck(:id) }
      .to eq [bucket_wp1.id, sprint_wp3.id, bucket_wp2.id]
    backlogs_page.expect_sprint_items_in_order(sprint, items: [sprint_wp1, sprint_wp2]
    )
    # The drag collapsed the batch onto the moved card, and the successful
    # move then cleared the selection — nothing stays selected.
    expect(backlogs_page.selected_card_ids).to be_empty
  end

  it "restores every row and keeps the selection when the server rejects the batch",
     with_ee: %i[readonly_work_packages] do
    backlogs_page.toggle_card(sprint_wp2)
    backlogs_page.toggle_card(sprint_wp3)

    # Invalidate one member server-side after the page rendered it movable:
    # a readonly status blocks the position write, so the batch 422s.
    readonly_status = create(:status, is_readonly: true)
    sprint_wp3.update_columns(status_id: readonly_status.id)

    # Not drag_work_package: it derives frame_reload: true from cross-list
    # identity, and a rejected move never reloads the frame.
    backlogs_page.drag_work_package_expecting_failure(sprint_wp2, after: bucket_wp1)

    # Rows restored, batch preserved for retry:
    backlogs_page.expect_sprint_items_in_order(sprint, items: [sprint_wp1, sprint_wp2, sprint_wp3]
    )
    expect(backlogs_page.selected_card_ids)
      .to contain_exactly(sprint_wp2.id.to_s, sprint_wp3.id.to_s)
    wait_for { sprint.work_packages_for(project).pluck(:id) }
      .to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
  end

  it "keeps a same-list batch reorder without reloading the frame" do
    backlogs_page.toggle_card(sprint_wp1)
    backlogs_page.toggle_card(sprint_wp2)

    # The order assertion below cannot tell an optimistic client-side move
    # from a reload that lands inside the wait window; the probe only flips
    # if `#backlogs_container` actually reloads.
    backlogs_page.install_backlogs_container_reload_probe

    backlogs_page.drag_work_package(sprint_wp1, after: sprint_wp3)

    backlogs_page.expect_sprint_items_in_order(sprint, items: [sprint_wp3, sprint_wp1, sprint_wp2]
    )
    backlogs_page.expect_backlogs_container_not_reloaded
    wait_for { sprint.work_packages_for(project).pluck(:id) }
      .to eq [sprint_wp3.id, sprint_wp1.id, sprint_wp2.id]
  end
end
