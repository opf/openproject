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

RSpec.describe "Move a backlog card via its menu",
               :js, :selenium do
  include RSpec::Wait

  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           manage_sprint_items
                           view_work_packages
                           edit_work_packages))
  end

  let(:type) { create(:type) }

  let!(:sprint) { create(:sprint, project:) }

  let!(:sprint_wp1) { create(:work_package, sprint:, type:, project:) }
  let!(:sprint_wp2) { create(:work_package, sprint:, type:, project:) }
  let!(:sprint_wp3) { create(:work_package, sprint:, type:, project:) }
  let!(:sprint_wp4) { create(:work_package, sprint:, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "moves the card up optimistically and persists" do
    backlogs_page
      .expect_sprint_items_in_order(sprint,
                                    items: [sprint_wp1, sprint_wp2, sprint_wp3, sprint_wp4])

    # Arm the reload probe before triggering the move: a full frame reload
    # (the old behaviour) would still leave the list in the expected order
    # once it settles, so the order assertion alone can't tell an optimistic
    # client-side move from a reload that happens to finish within the wait
    # window. The probe does: it only flips if `#backlogs_container` actually
    # reloads.
    backlogs_page.install_backlogs_container_reload_probe

    # `wait: false` skips the turbo-stream/frame-reload wait baked into the
    # helper: a same-list menu move now settles via a background fetch, not a
    # frame reload, so the assertion right below has to observe the DOM before
    # that request has any chance to complete.
    backlogs_page
      .click_in_sprint_story_move_menu(sprint_wp2, "Move up", wait: false)

    backlogs_page
      .expect_sprint_items_in_order(sprint,
                                    items: [sprint_wp2, sprint_wp1, sprint_wp3, sprint_wp4])

    backlogs_page.expect_backlogs_container_not_reloaded

    wait_for do
      WorkPackage.where(sprint:).order_by_position.pluck(:id)
    end.to eq([sprint_wp2.id, sprint_wp1.id, sprint_wp3.id, sprint_wp4.id])

    # Reloading confirms the move was actually persisted server-side, not just
    # reflected in the client's optimistic DOM state.
    backlogs_page.visit!
    backlogs_page
      .expect_sprint_items_in_order(sprint,
                                    items: [sprint_wp2, sprint_wp1, sprint_wp3, sprint_wp4])
  end
end
