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

# The sprint/bucket/inbox lists opt into `empty_state_behavior: :dynamic`
# (DREAM-801): a Stimulus controller inserts the blankslate row the instant
# the list drains to zero visible rows, and removes it the instant a row
# reappears, without a page reload. This proves the observable END STATES
# only (blankslate present once the drag settles, gone again once it
# settles back) — the *instant* insertion itself, with no network involved,
# is owned by the controller's own vitest suite (Task 4). A feature spec
# cannot prove "appears before the server responds" without artificially
# delaying the request.
RSpec.describe "Dynamic empty state for backlogs lists",
               :js, :selenium, :settings_reset do
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
  let!(:bucket) { create(:backlog_bucket, project:, name: "Backlog bucket") }
  let!(:work_package) { create(:work_package, sprint:, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "shows the sprint blankslate once its only card leaves, and hides it again once one returns" do
    blankslate_title = I18n.t("backlogs.sprint_component.blankslate_title", name: sprint.name)

    within_test_selector("sprint-#{sprint.id}") do
      expect(page).to have_no_css("[data-empty-list-item='true']")
    end

    backlogs_page.drag_work_package_to_backlog_bucket(work_package, bucket)

    within_test_selector("sprint-#{sprint.id}") do
      expect(page).to have_css("[data-empty-list-item='true']", text: blankslate_title)
    end

    backlogs_page.drag_work_package_to_sprint(work_package, sprint)

    within_test_selector("sprint-#{sprint.id}") do
      expect(page).to have_no_css("[data-empty-list-item='true']")
    end
  end
end
