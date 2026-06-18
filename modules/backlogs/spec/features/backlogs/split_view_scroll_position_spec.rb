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

RSpec.describe "Backlog split view scroll position",
               :js, :settings_reset do
  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }

  let!(:sprint) { create(:sprint, project:) }

  # Enough work packages to make the backlog list scrollable.
  let!(:work_packages) do
    Array.new(30) do |i|
      create(:work_package, subject: "Story #{i + 1}", sprint:, type:, project:)
    end
  end

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints manage_sprint_items view_work_packages edit_work_packages]
           })
  end

  before do
    backlogs_page.visit!
  end

  # The backlog is scrolled by either #content or #content-body depending on
  # whether the side panel is shown, so we read whichever currently holds the
  # scroll offset.
  def backlog_scroll_top
    page.evaluate_script(
      "Math.max(" \
      "(document.getElementById('content') || {}).scrollTop || 0," \
      "(document.getElementById('content-body') || {}).scrollTop || 0)"
    )
  end

  it "keeps the refinement spot when opening and closing the side panel" do
    target = work_packages.last
    target_card = page.find("[data-test-selector='work-package-#{target.id}']")
    page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' });", target_card)

    scroll_position = backlog_scroll_top
    expect(scroll_position).to be > 0

    # Opening the side panel must not scroll the backlog to the top.
    split_view = backlogs_page.open_work_package_details(target)

    retry_block do
      expect(backlog_scroll_top).to be_within(25).of(scroll_position)
    end

    # Closing the side panel must restore the position as well.
    split_view.close
    expect(page).to have_no_test_selector("wp-details-tab-component--close")

    retry_block do
      expect(backlog_scroll_top).to be_within(25).of(scroll_position)
    end
  end
end
