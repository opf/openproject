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
require_relative "../../support/pages/backlog"

RSpec.describe "Changing the assignee in the split view", :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints manage_sprint_items
                           view_work_packages edit_work_packages]
           })
  end
  let(:backlogs_page) { Pages::Backlog.new(project) }

  let!(:sprint) { create(:sprint, project:) }
  let!(:assignee) do
    create(:user, firstname: "First", lastname: "Assignee",
                  member_with_permissions: { project => %i[work_package_assigned] })
  end
  let!(:other_assignee) do
    create(:user, firstname: "Other", lastname: "Assignee",
                  member_with_permissions: { project => %i[work_package_assigned] })
  end
  let!(:work_package) { create(:work_package, project:, sprint:, assigned_to: assignee) }

  current_user { user }

  # Narrow cards hide the assignee name, leaving the avatar and its tooltip.
  def avatar_of(principal)
    "[title='#{principal.name}']"
  end

  before do
    backlogs_page.visit!
    backlogs_page.work_package_card(work_package).find(avatar_of(assignee))
  end

  it "removes the assignee from the card when unassigning" do
    split_view = backlogs_page.open_work_package_details(work_package)
    split_view.edit_field(:assignee).unset_value

    backlogs_page.expect_and_dismiss_toaster(message: "Successful update")
    expect(backlogs_page.work_package_card(work_package)).to have_no_css(avatar_of(assignee))
  end

  it "shows the new assignee on the card when changing the assignee" do
    split_view = backlogs_page.open_work_package_details(work_package)
    split_view.edit_field(:assignee).update(other_assignee.name)

    backlogs_page.expect_and_dismiss_toaster(message: "Successful update")
    card = backlogs_page.work_package_card(work_package)
    expect(card).to have_css(avatar_of(other_assignee))
    expect(card).to have_no_css(avatar_of(assignee))
  end
end
