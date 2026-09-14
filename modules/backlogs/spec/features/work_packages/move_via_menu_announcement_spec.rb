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

RSpec.describe "Live region announcements for backlog card menu moves",
               :js do
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

  let!(:sprint) { create(:sprint, name: "Sprint 1", project:) }

  let!(:sprint_wp1) { create(:work_package, subject: "First story", sprint:, type:, project:) }
  let!(:sprint_wp2) { create(:work_package, subject: "Second story", sprint:, type:, project:) }
  let!(:sprint_wp3) { create(:work_package, subject: "Third story", sprint:, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  # Primer's live-region element stores the message inside an open shadow
  # root, not as host text, so it has to be read through its getMessage API.
  def polite_announcement
    page.evaluate_script("document.querySelector('live-region')?.getMessage('polite')")
  end

  it "announces the move and persists it" do
    # The announcement fires with the optimistic reorder, before the request
    # settles, so it is asserted separately from persistence below.
    backlogs_page.click_in_sprint_story_move_menu(sprint_wp2, "Move up", wait: false)

    wait_for { polite_announcement }
      .to eq("#{sprint_wp2.to_fs(:caption)} moved to position 1 of 3")

    wait_for do
      WorkPackage.where(sprint:).order_by_position.pluck(:id)
    end.to eq([sprint_wp2.id, sprint_wp1.id, sprint_wp3.id])
  end
end
