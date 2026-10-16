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

RSpec.describe "Notification center uses displayId when navigating to the work package",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  # Classic mode is a behavioural no-op: the URL helpers and the
  # resolveRoutingId bridge both collapse to the numeric id when semantic
  # mode is off. Covering semantic-only where the bug actually manifests.

  let(:project)      { create(:project, identifier: "NOTIFNAV") }
  let(:work_package) { create(:work_package, project:, subject: "Semantic notif WP") }
  let(:recipient) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end
  let(:notification) do
    create(:notification,
           recipient:,
           resource: work_package,
           journal: work_package.journals.last)
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new(work_package) }

  current_user { recipient }

  before do
    work_package.allocate_and_register_semantic_id
    notification # realise
  end

  it "opens the split view at the semantic identifier URL" do
    semantic_id = work_package.reload.identifier
    visit notifications_path

    center.click_item(notification)
    split_screen.expect_open

    expect(page).to have_current_path(
      "/notifications/details/#{semantic_id}/activity"
    )
    center.expect_item_selected(notification)
  end

  it "renders the notification's WP link with the semantic identifier in its href" do
    semantic_id = work_package.reload.identifier
    visit notifications_path

    # Wait for the entry to finish loading the WP
    expect(page).to have_css(".op-ian-item--work-package-id-link", text: semantic_id)
    link = page.find(".op-ian-item--work-package-id-link")

    expect(link[:href]).to include("/work_packages/#{semantic_id}")
    expect(link[:href]).not_to include("/work_packages/#{work_package.id}")
  end
end
