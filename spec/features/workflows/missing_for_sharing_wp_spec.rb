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

RSpec.describe "Configuring the workflow for work package sharing",
               with_config: { show_warning_bars: true },
               with_ee: %i[work_package_sharing] do
  let!(:role) { create(:project_role) }
  let!(:work_package_role) { create(:edit_work_package_role) }
  let!(:type) { create(:type) }
  let!(:start_status) { create(:status) }
  let!(:end_status) { create(:status) }
  let!(:workflow) do
    create(:workflow,
           role_id: role.id,
           type_id: type.id,
           old_status_id: start_status.id,
           new_status_id: end_status.id,
           author: false,
           assignee: false)
  end

  current_user { create(:admin) }

  before do
    visit home_url
  end

  it "shows a warning until a workflow is configured for the work package edit role" do
    # There is a warning bar at the bottom informing of the missing workflow
    within ".warning-bar--item" do
      expect(page)
        .to have_content("No workflow is configured for the '#{work_package_role.name}' role. " \
                         "Without a workflow, the shared with user cannot alter the status of the work package.")

      click_link "Configure the workflows in the administration."
    end

    # On the copy workflow form, select the already existing workflow for copying
    select type.name, from: "source_type_id"
    select role.name, from: "source_role_id"
    select type.name, from: "target_type_ids"
    select work_package_role.name, from: "target_role_ids"

    page.find_test_selector("op-admin-workflows--button-copy").click

    # Copying succeeds which results in the edit role having a workflow and the warning disappearing.
    expect(page)
      .to have_content "Successful update"

    expect(Workflow.where(role_id: work_package_role.id,
                          type_id: type.id,
                          old_status_id: start_status.id,
                          new_status_id: end_status.id,
                          author: false,
                          assignee: false).count).to eq(1)

    expect(page)
      .to have_no_css(".warning-bar--item")
  end
end
