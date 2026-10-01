# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Backlog journal activity on the work package activity page", :js,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, name: "Sprint 1", project:) }
  shared_let(:bucket) { create(:backlog_bucket, name: "Bucket 1", project:) }
  shared_let(:work_package) { create(:work_package, :created_in_past, created_at: 1.day.ago, project:) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  before do
    work_package.update!(sprint:)
    work_package.update!(sprint: nil, backlog_bucket: bucket)
  end

  context "when the user has view_sprints permission" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages view_sprints] }) }

    it "shows sprint and backlog bucket changes in the activity feed" do
      wp_page.visit!
      wp_page.wait_for_activity_tab

      activity_tab.expect_journal_changed_attribute(text: /Sprint 1/)
      activity_tab.expect_journal_changed_attribute(text: /Bucket 1/)
      expect(page).to have_no_text(I18n.t(:text_journal_permission_denied))
    end
  end

  context "when the user lacks view_sprints permission" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "shows a permission denied message instead of sprint and backlog bucket changes" do
      wp_page.visit!
      wp_page.wait_for_activity_tab

      expect(page).to have_no_text("Sprint 1")
      expect(page).to have_no_text("Bucket 1")
      # count: 3, because the sprint was also unassigned.
      expect(page).to have_text(I18n.t(:text_journal_permission_denied), count: 3)
    end
  end
end
